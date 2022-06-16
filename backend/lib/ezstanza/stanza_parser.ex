defmodule Ezstanza.StanzaParser do

  @directives_exact [
    "AddUserHeader",
    "Referer"
  ]

  @option_directive_options [
    "AcceptX-Forwarded-For",
    "AllowSendGZip",
    "AllowWebSubdirectories",
    "BlockCountryChange",
    "Cookie",
    "DomainCookieOnly",
    "NoCookie",
    "CookiePassThrough",
    "CSRFToken",
    "HideEZproxy",
    "NoHideEZproxy",
    "HttpsHyphens",
    "NoHttpsHyphens",
    "NoRedirectPatch",
    "NoX-Forwarded-For",
    "X-Forwarded-For"
  ]

  @directives_normalize %{
    "H" => "Host",
    "D" => "Domain",
    "HJ" => "HostJavaScript",
    "T" => "Title",
    "U" => "URL"
  }

  @directives_starts_with [
    "AddUserHeader",
    "AllowVars",
    "AnonymousURL",
    "BinaryTimeout",
    "ByteServe",
    "ClientTimeout",
    "Cookie",
    "CookieFilter",
    "DbVar0",
    "DbVar1",
    "DbVar2",
    "DbVar3",
    "DbVar4",
    "DbVar5",
    "DbVar6",
    "DbVar7",
    "DbVar8",
    "DbVar9",
    "Description",
    "D",
    "Domain",
    "DJ",
    "DomainJavaScript",
    "EBLSecret",
    "EncryptVar",
    "Find",
    "Replace",
    "FormSelect",
    "FormSubmit",
    "FormVariable",
    "H",
    "Host",
    "HJ",
    "HostJavaScript",
    "HTTPHeader",
    "HTTPMethod",
    "MimeFilter",
    "NeverProxy",
    "ProxyHostnameEdit",
    "PHE",
    "RedirectSafe",
    "Referer",
    "RemoteTimeout",
    "T",
    "Title",
    "TokenKey",
    "TokenSignatureKey",
    "U",
    "URL",
    "UsageLimit"
  ]

  def parse_directory(dirname) do
    Path.wildcard(Path.join(dirname, "*.txt"))
    |> Enum.reduce(%{}, fn filename, acc ->
      Map.put(acc, filename, parse_file(filename))
    end)
  end

  # This sucks
  def invalid_stanza_files(dirname) do
    Enum.each(parse_directory(dirname), fn {filename, stanzas} ->
      case Keyword.get_values(stanzas, :error) do
        [] -> IO.puts("#{filename}: ok")
        errors ->
          IO.puts("#{filename}:")
          Enum.map(errors, fn {_stanza, reason} ->
            IO.puts(reason)
          end)
      end
    end)
  end

  def parse_file(filename) do
    File.stream!(filename)
    |> parse_stanza_lines()
    |> Enum.reject(fn %{status: status} -> status == :error end) #TODO: Do not include status?
    |> chunk_by_stanza()
    |> Enum.map(fn stanza ->
      case validate_stanza(stanza) do
        [] ->
          {:ok, stanza}
        errors ->
          {:error, {stanza, errors}} #TODO: This format sucks?
      end
    end)
  end

  def parse_string(stanza_string) do
    stanza = stanza_string
             |> String.split("\n")
             |> parse_stanza_lines()
    case validate_stanza(stanza) ++ validate_stanza_lines(stanza) do
      [] -> {:ok, stanza}
      errors -> {:error, errors}
    end
  end

  def parse_stanza_lines(stanza_lines) do
    stanza_lines
    |> Enum.map(&parse_line/1)
    |> Enum.with_index()
    |> Enum.map(fn {{status, cmd, value}, idx} -> %{status: status, cmd: cmd, value: value, line: idx + 1} end)
  end

  def chunk_by_stanza(lines) do
    chunk_blocks = fn
      line, [] ->
        {:cont, [line]}
      line, [prev_line | _tail] = acc ->
        case {line, prev_line} do
          {%{cmd: cmd}, %{cmd: prev_cmd}} when cmd != "" and prev_cmd == "" ->
            {:cont, acc, [line]}
          _ ->
            {:cont, [line | acc]}
        end
    end
    add_last_block = fn
      [] ->
        {:cont, []}
      acc ->
        {:cont, acc, []}
    end

    lines
    |> Enum.chunk_while([], chunk_blocks, add_last_block)
    |> Enum.map(&Enum.reverse/1)
    |> IO.inspect()
    |> Enum.reduce({[], []}, fn
      block_lines, {acc, prev_comment_lines} ->
        if lines_contain_directive(block_lines) do
          # Pass next previous_comment_lines as empty list
          # so don't waste time looking for comments next time
          case filter_lines_by_cmd("#", prev_comment_lines) do
            [_comment_line] ->
              # Prepend comment block if single-line comment
              {[prev_comment_lines ++ block_lines | acc], []}
            _ ->
              {[ block_lines | acc], []}
          end
        else
          # Don't include comment blocks
          {acc, block_lines}
        end
    end)
    |> case do
      {stanzas, _prev_comment_lines} -> stanzas
    end
  end

  def validate_stanza(stanza) do
    Enum.reduce([
      &validate_title/1
    ], [], fn validator, errors ->
      case validator.(stanza) do
        :ok -> errors
        {:error, error} -> [error | errors]
      end
    end)
  end

  def validate_stanza_lines(stanza) do
    Enum.reduce(stanza, [], fn stanza_line, errors ->
      case stanza_line do
        %{status: :error, cmd: cmd, value: value, line: line} ->
          [{cmd, line} | errors]
      end
    end)
  end

  def validate_title(stanza) do
    case Enum.count(stanza, fn %{cmd: cmd} -> cmd == "Title" end) do
      1 -> :ok
      0 -> {:error, :missing_title}
      _ -> {:error, :multiple_titles}
    end
  end

  def error_message(error) do
    messages = %{
      :missing_title => "Stanza requires a title",
      :multiple_title => "Stanza has multiple titles"
    }
    Map.get(messages, error, "Unknown error")
  end

  def lines_contain_directive(lines) do
    Enum.any?(lines, fn %{cmd: cmd} -> cmd != "" && cmd != "#" end)
  end

  def filter_lines_by_cmd(cmd, lines) do
    Enum.filter(lines, fn
      %{cmd: ^cmd} -> true
      _ -> false
    end)
  end

  def normalize_directive(directive) do
    Map.get(@directives_normalize, directive, directive)
  end

  # Newline
  def parse_line("") do
    {:ok, "", nil}
  end
  # utf-8/binary lenght?
  def parse_line("\n") do
    {:ok, "", nil}
  end

  for directive_starts_with <- @directives_starts_with do
    def parse_line(<<unquote(directive_starts_with), " ", rest::binary>> = line) do
      directive = unquote(directive_starts_with)
      value = String.trim(rest)
      if value != "" do
        {:ok, normalize_directive(directive), value}
      else
        if Enum.member?(@directives_exact, directive) do
          parse_line(directive)
        else
          {:error, line, nil}
        end
      end
    end
  end

  def parse_line(<<"Option ", rest::binary>>) do
    # Allow permit more whitespace before and after option
    option = String.trim(rest)
    if Enum.member?(@option_directive_options, option) do
      {:ok, "Option", option}
    else
      {:error, "Option " <> rest, nil}
    end
  end

  # special case for comments
  def parse_line(<<"#", comment::binary>>) do
    {:ok, "#", comment}
  end

  # Important this is placed last else directives with same names that
  # have values will be caught here also (and result in error)
  for directive_exact <- @directives_exact do
    def parse_line(<< unquote(directive_exact), rest::binary>> = line) do
      if String.trim(rest) == "" do
        {:ok, unquote(directive_exact), nil}
      else
        {:error, line, nil}
      end
    end
  end

  def parse_line(invalid_line) do
    {:error, invalid_line, nil}
  end

end
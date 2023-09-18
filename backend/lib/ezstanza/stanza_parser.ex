defmodule Ezstanza.StanzaParser do

  alias Ezstanza.StanzaParser.StanzaLine

  # TODO: Structs/data types for stanza file etc!

  @directives_allow_bare [
    "AddUserHeader",
    "Referer"
  ]

  @directives_allow_bare_lowercase_map Enum.map(
    @directives_allow_bare,
    &({String.downcase(&1), &1})
  ) |> Enum.into(%{})

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

  @option_directive_options_lowercase_map Enum.map(
    @option_directive_options,
    &({String.downcase(&1), &1})
  ) |> Enum.into(%{})

  @directives_normalize %{
    "h" => "host",
    "d" => "domain",
    "dj" => "domainjavascript",
    "hj" => "hostjavascript",
    "t" => "title",
    "u" => "url",
    "phe" => "proxyhostnameedit"
  }

  # TODO: Merge in keys from normalize instead of repeating?
  @directives [
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
    "Domain",
    "DomainJavaScript",
    "EBLSecret",
    "EncryptVar",
    "Find",
    "Replace",
    "FormSelect",
    "FormSubmit",
    "FormVariable",
    "Host",
    "HostJavaScript",
    "HTTPHeader",
    "HTTPMethod",
    "MimeFilter",
    "NeverProxy",
    "ProxyHostnameEdit",
    "RedirectSafe",
    "Referer",
    "RemoteTimeout",
    "Title",
    "TokenKey",
    "TokenSignatureKey",
    "URL",
    "UsageLimit"
  ] ++ Map.keys(@directives_normalize)

  @directives_lowercase_map Enum.map(
    @directives,
    &({String.downcase(&1), &1})
  ) |> Enum.into(%{})

  def parse_directory(dirname) do
    Path.wildcard(Path.join(dirname, "*.txt"))
    |> parse_files()
  end

  def parse_files(filenames) do
    Enum.map(filenames, fn filename ->
      {filename, parse_file(filename)}
    end)
    |> Enum.into(%{})
  end

  def validate_stanza_files(stanza_files) do
    errors = Enum.reduce(stanza_files, %{}, fn {filename, stanzas}, acc ->
      case validate_stanzas(stanzas) do
        {:error, errors} ->
          Map.put(acc, filename, errors)
        :ok -> acc
      end
    end)
    if errors == %{} do
      :ok
    else
      {:error, errors}
    end
  end

  # remove?
  def validate_stanza_file({filename, stanzas}) do
    case validate_stanzas(stanzas) do
      {:error, errors} ->
        {:error, {filename, errors}}
      :ok ->
        {:ok, filename}
    end
  end

  def validate_stanzas(stanzas) do
    line_errors = Enum.map(stanzas, &line_errors/1)
                  |> Enum.concat()
    structure_errors = Enum.reduce(stanzas, [], fn [ %{line: line} | _lines ] = stanza, acc ->
      case structure_errors(stanza) do
        [] -> acc
        errors -> [%{line: line, errors: errors} | acc]
      end
    end)
    |> Enum.reverse()

    if length(line_errors) > 0 or length(structure_errors) > 0 do
      {:error, %{structure_errors: structure_errors, line_errors: line_errors}}
    else
      :ok
    end
  end

  def validate_directory(dirname) do
    parse_directory(dirname)
    |> validate_stanza_files()
  end

  def parse_file(filename) do
    File.stream!(filename)
    |> parse_stanza_lines()
    #|> Enum.reject(fn %{status: status} -> status == :error end) #TODO: Do not include status?
    |> chunk_by_stanza()
  end

  def validate_file(filename) do
    parse_file(filename)
    |> validate_stanzas()
  end

  #TODO: No longer used?
  def validate_stanza(stanza) do
    validate_stanzas([stanza])
  end

  def parse_string(stanza_string) do
    stanza_string
    |> String.split("\n")
    |> parse_stanza_lines()
  end

  def normalize_string(stanza_string) do
    stanza_string
    |> parse_string()
    |> stanza_to_string()
  end

  def stanza_to_string(stanza) do
    stanza
    |> Enum.map(&to_string/1)
    |> Enum.join("\n")
  end

  def stanza_errors(stanza) do
    structure_errors(stanza) ++ line_errors(stanza)
  end

  def parse_stanza_lines(stanza_lines) do
    stanza_lines
    |> Enum.map(&parse_line/1)
    |> Enum.with_index()
    |> Enum.map(fn {{status, cmd, value}, idx} ->
      %StanzaLine{status: status, cmd: cmd, value: value, line: idx + 1}
    end)
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
    |> Enum.reduce({[], []}, fn
      block_lines, {acc, prev_comment_lines} ->
        if lines_contain_directive(block_lines) do
          case get_lines(prev_comment_lines, :cmd, "#") do
            [comment_line] ->
              # Prepend comment block if single-line comment
              {[[comment_line | block_lines] | acc], []}
            _ ->
              {[ block_lines | acc], []}
          end
        else
          # Don't include comment blocks
          # but stash in accumulator so possibly
          # can prepend to next block if single
          # line comment
          {acc, block_lines}
        end
    end)
    |> case do
      {stanzas, _prev_comment_lines} -> stanzas
    end
    |> Enum.reverse()
  end

  def structure_errors(stanza) do
    Enum.reduce([
      &validate_title/1
    ], [], fn validator, errors ->
      case validator.(stanza) do
        :ok -> errors
        {:error, error} -> [error | errors]
      end
    end)
  end

  def line_errors(stanza) do
    Enum.reduce(stanza, [], fn
      # TODO: Include value?
      %StanzaLine{status: :error, cmd: cmd, value: _value, line: line}, errors ->
        [{cmd, line} | errors]
      _, errors ->
        errors
    end)
  end

  def validate_title(stanza) do
    case get_lines(stanza, :cmd, "Title") do
      [_line] ->
        :ok
      [] -> {:error, :missing_title}
      _ ->
        {:error, :multiple_titles}
    end
  end

  def error_message(error) do
    messages = %{
      :missing_title => "Stanza requires a title",
      :multiple_titles => "Stanza has multiple titles"
    }
    Map.get(messages, error, "Unknown error")
  end

  def lines_contain_directive(lines) do
    Enum.any?(lines, fn %{cmd: cmd} -> cmd != "" && cmd != "#" end)
  end

  def get_lines(lines, field, value) do
    Enum.filter(lines, fn
      %{^field => ^value} -> true
      _ -> false
    end)
  end

  def normalize_directive(directive) do
    Map.get(@directives_normalize, directive, directive)
  end

  def parse_line(line) do
    # Normalize directives to lowercase
    # Allow space before directive or not?
    Regex.replace(~r/^(\s*[a-zA-Z0-9]+)/, line,  fn _, cmd -> cmd |> String.trim() |> String.downcase() end)
    |> do_parse_line(line)
  end

  # Newline
  def do_parse_line("", _orig) do
    {:ok, "", nil}
  end
  # utf-8/binary lenght?
  def do_parse_line("\n", _orig) do
    {:ok, "", nil}
  end

  for directive <- Map.keys(@directives_lowercase_map) do
    def do_parse_line(<<unquote(directive), " ", rest::binary>>, orig) do
      directive = unquote(directive)
      value = String.trim(rest)
      if value != "" do
        directive = Map.get(@directives_lowercase_map, normalize_directive(directive))
        {:ok, directive, value}
      else
        if Enum.member?(@directives_allow_bare, directive) do
          do_parse_line(directive, orig)
        else
          {:error, orig, nil}
        end
      end
    end
  end

  def do_parse_line(<<"option ", rest::binary>>, orig) do
    # Allow permit more whitespace before and after option
    option = Map.get(
      @option_directive_options_lowercase_map,
      rest |> String.trim() |> String.downcase(),
      false
    )
    if option do
      {:ok, "Option", option}
    else
      {:error, orig, nil}
    end
  end

  # special case for comments
  def do_parse_line(<<"#", comment::binary>>, _orig) do
    {:ok, "#", String.trim(comment)}
  end

  # Important this is placed last else directives with same names that
  # have values will be caught here also (and result in error)
  for directive <- Map.keys(@directives_allow_bare_lowercase_map) do
    def do_parse_line(<<unquote(directive), rest::binary>>, _orig) do
      value = String.trim(rest)
      {
        :ok,
        Map.get(@directives_allow_bare_lowercase_map, unquote(directive)),
        (if value == "", do: nil, else: value)
      }
    end
  end

  def do_parse_line(line, orig) do
    if String.trim(line) == "" do
      do_parse_line("", orig)
    else
      {:error, line, nil}
    end
  end

end

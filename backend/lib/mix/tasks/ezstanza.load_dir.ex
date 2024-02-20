defmodule Mix.Tasks.Ezstanza.LoadDir do
  @moduledoc "Loads stanzas from directory, files may contain multiple stanzas separated by whitespace"
  @shortdoc "Loads stanzas from directory"

  alias Ezstanza.StanzaParser
  alias Ezstanza.StanzaParser.StanzaLine

  alias Ezstanza.Stanzas

  @requirements ["app.config", "app.start"] # Dont need config when start?

  use Mix.Task


  defp import_stanza(attrs, title, filename) do
    case Stanzas.create_stanza(attrs) do
      {:ok, _stanza} ->
        Mix.shell().info("Imported #{title} from #{filename}")
      {:error, error} ->
        Mix.shell().error("Import #{title} from #{filename} failed")
        # TODO: Output changeset errors or reasons
    end
  end

  @impl Mix.Task
  def run(args) do
    # TODO: Support extension + recursive? User id
    filenames = Enum.map(args, fn dirname ->
      Path.wildcard(Path.join(dirname, "*.txt"))
    end)
    |> Enum.concat()

    stanza_files = StanzaParser.parse_files(filenames)
    case StanzaParser.validate_stanza_files(stanza_files) do
      {:error, errors} ->
        #Mix.shell().info(IO.inspect(errors))
        Mix.shell().info("Stanzas could not be loaded, errors:")
        Mix.shell().info(inspect(errors, pretty: true))
        #Enum.each(errors, fn {filename, errors} ->
        #  Mix.shell().info("File: #{filename}")
        #end)
      :ok ->
        stanza_files
        |> Enum.each(fn {filename, stanzas} ->
          stanzas
          |> Enum.each(fn stanza ->
            [%StanzaLine{value: title}] = StanzaParser.get_lines(stanza, :cmd, "Title")
            # Option for adding filename?
            filename = Path.basename(filename)
            imported_message = "Imported from #{filename}"
            stanza = [%StanzaLine{cmd: "#", value: imported_message, status: :ok} | stanza]
            body = StanzaParser.stanza_to_string(stanza)
            attrs = %{
              "name" => title,
              "user_id" => 1,
              "body" => StanzaParser.stanza_to_string(stanza),
              "log_message" => imported_message
            }
            # TODO: Option to match on body/name
            case Stanzas.list_stanza_revisions(%{"body" => body}) do
              [] ->
                import_stanza(attrs, title, filename)
              _ ->
                Mix.shell().info("#{title} in #{filename} already imported")
            end
          end)
        end)
        Mix.shell().info("SUCCESS")
    end
  end
end

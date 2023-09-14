defmodule Ezstanza.StanzaParser.StanzaLine do
  defstruct [:status, :cmd, :value, :line]

  alias Ezstanza.StanzaParser.StanzaLine

  defimpl String.Chars, for: StanzaLine do
    def to_string(stanza_line) do
      stanza_line
      |> Map.take([:cmd, :value])
      |> Map.values()
      |> Enum.join(" ")
    end
  end
end

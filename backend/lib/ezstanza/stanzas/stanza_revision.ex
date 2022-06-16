defmodule Ezstanza.Stanzas.StanzaRevision do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Stanzas.Stanza
  alias Ezstanza.Accounts.User

  alias Ezstanza.StanzaParser

  schema "stanza_revision" do
    field :body, :string
    belongs_to :stanza, Stanza
    belongs_to :user, User

    timestamps()
  end
  @spec validate_stanza(Changeset.t(), atom) :: Changeset.t()
  def validate_stanza(changeset, field) do
    validate_change changeset, field, fn _, value ->
      case StanzaParser.parse_string(value) do
        {:ok, _stanza} -> []
        {:error, errors} ->
          Enum.map(errors, fn
            {cmd, line} ->
              {field, {"Invalid stanza directive \"%{cmd}\", line %{line}", [cmd: cmd, line: line]}}
            error ->
              {field, StanzaParser.error_message(error)}
          end)
       end
    end
  end

  @doc false
  def changeset(stanza_revision, attrs) do
    stanza_revision
    |> cast(attrs, [:body, :stanza_id, :user_id])
    |> validate_required([:body, :stanza_id, :user_id])
    |> validate_stanza(:body)
  end
end
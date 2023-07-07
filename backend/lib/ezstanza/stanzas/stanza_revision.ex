defmodule Ezstanza.Stanzas.StanzaRevision do
  use Ecto.Schema
  import Ecto.Changeset

  alias Ezstanza.Stanzas.Stanza
  alias Ezstanza.Configs.ConfigRevision
  alias Ezstanza.Configs.Config
  alias Ezstanza.Deployments.Deployment
  alias Ezstanza.Accounts.User

  alias Ezstanza.StanzaParser

  schema "stanza_revision" do
    field :body, :string
    field :log_message, :string
    field :is_current_revision, :boolean, virtual: true
    belongs_to :stanza, Stanza
    belongs_to :user, User
    many_to_many :deployments, Deployment,
      join_through: "deployment_stanza_revision",
      on_replace: :delete #???

    many_to_many :current_deployments, Deployment,
      join_through: "stanza_revision_current_deployment"

    timestamps()
  end
  @spec validate_stanza(Changeset.t(), atom) :: Changeset.t()
  def validate_stanza(changeset, field) do
    validate_change changeset, field, fn _, value ->
      value
      |> StanzaParser.parse_string()
      |> StanzaParser.stanza_errors()
      |> case do
        [] -> []
        errors ->
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
    |> cast(attrs, [:body, :log_message, :stanza_id, :user_id])
    |> validate_required([:body, :stanza_id, :user_id]) # :log_message?
    |> validate_stanza(:body)
  end
end

defmodule Ezstanza.DeploymentProvider.SSH do
  use Ezstanza.DeploymentProvider

  form_schema do
    form_field :hostname, :string,
      label: "Hostname",
      help_text: "SSH hostname",
      component: :text,
      required: true
    form_field :port, :integer,
      label: "Port",
      help_text: "SSH port",
      component: :number,
      required: true
    form_field :user, :string,
      label: "User",
      help_text: "SSH user",
      component: :text,
      required: true
    form_field :path, :string,
      label: "Path",
      help_text: "Remote deployment path",
      component: :text,
      required: true
  end

  @impl Ezstanza.DeploymentProvider
  def changeset_alter(changeset) do
    changeset
  end

end

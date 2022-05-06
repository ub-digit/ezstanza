defmodule EzstanzaWeb.UserRegistrationView do

  use EzstanzaWeb, :view
  alias EzstanzaWeb.UserRegistrationView

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserRegistrationView, "user.json", as: :user)}
  end

  def render("user.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
      source: user.source,
      source_id: user.source_id
    }
  end
end

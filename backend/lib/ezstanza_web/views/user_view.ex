defmodule EzstanzaWeb.UserView do
  use EzstanzaWeb, :view
  alias EzstanzaWeb.UserView

  def render("index.json", %{users: users}) do
    %{data: render_many(users, UserView, "user.json")}
  end

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json")}
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

  def render("user_snippet.json", %{user: user}) do
    %{
      id: user.id,
      name: user.name,
      username: user.username,
      email: user.email,
    }
  end

end

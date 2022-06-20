defmodule EzstanzaWeb.UserRegistrationView do

  use EzstanzaWeb, :view
  #alias EzstanzaWeb.UserRegistrationView
  alias EzstanzaWeb.UserView

  def render("show.json", %{user: user}) do
    %{data: render_one(user, UserView, "user.json", as: :user)}
  end

 end

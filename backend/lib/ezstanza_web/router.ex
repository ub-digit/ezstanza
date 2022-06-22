defmodule EzstanzaWeb.Router do
  use EzstanzaWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug EzstanzaWeb.Plug.Auth
  end

  pipeline :api_require_authenticated do
    plug EzstanzaWeb.Plug.RequireAuthenticated
  end

  #pipeline :api_require_unauthenticated do
  #  plug EzstanzaWeb.Plug.RequireNotauthenticated
  #  plug EzstanzaWeb.Plug.RequireUnauthenticated?
  #end

  scope "/api", EzstanzaWeb do
    pipe_through :api
    post "/registration", UserRegistrationController, :create
    resources "/session", SessionController, singleton: true, only: [:create, :delete]
    post "/session/delete", SessionController, :delete # Since vue auth doesn't support DELETE
    post "/session/renew", SessionController, :renew
  end

  scope "/api", EzstanzaWeb do
    pipe_through [:api, :api_require_authenticated]
    get "/session/user", SessionController, :user
    # Just for testing
    get "/users", UserController, :index
    resources "/stanzas", StanzaController
    post "/stanza/validate_lines", StanzaController, :validate_lines
    resources "/tags", TagController
  end

  # Enables LiveDashboard only for development
  #
  # If you want to use the LiveDashboard in production, you should put
  # it behind authentication and allow only admins to access it.
  # If your application does not have an admins-only section yet,
  # you can use Plug.BasicAuth to set up some basic authentication
  # as long as you are also using SSL (which you should anyway).
  if Mix.env() in [:dev, :test] do
    import Phoenix.LiveDashboard.Router

    scope "/" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: EzstanzaWeb.Telemetry
    end
  end

  # Enables the Swoosh mailbox preview in development.
  #
  # Note that preview only shows emails that were sent by the same
  # node running the Phoenix server.
  if Mix.env() == :dev do
    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

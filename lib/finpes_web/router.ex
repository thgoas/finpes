defmodule FinpesWeb.Router do
  use FinpesWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :fetch_session
  end

  pipeline :api_authenticated do
    plug FinpesWeb.Plugs.Finpes
  end

  pipeline :api_pro_only do
    plug FinpesWeb.Plugs.Finpes
    plug FinpesWeb.Plugs.RequirePlan, ["pro", "premium"]
  end

  scope "/api", FinpesWeb do
    pipe_through :api

    post "/login", SessionController, :create

    post "/register", UserController, :create
  end

  scope "/api", FinpesWeb do
    pipe_through [:api, :api_authenticated]

    post "/logout", SessionController, :delete
    get "/me", UserController, :me

    resources "/wallets", WalletController, except: [:new, :edit]
  end

  scope "/api/pro", FinpesWeb do
    pipe_through [:api, :api_pro_only]

    get "/dashboard", UserController, :premium_dashboard
  end
  # Enable LiveDashboard and Swoosh mailbox preview in development
  if Application.compile_env(:finpes, :dev_routes) do
    # If you want to use the LiveDashboard in production, you should put
    # it behind authentication and allow only admins to access it.
    # If your application does not have an admins-only section yet,
    # you can use Plug.BasicAuth to set up some basic authentication
    # as long as you are also using SSL (which you should anyway).
    import Phoenix.LiveDashboard.Router

    scope "/dev" do
      pipe_through [:fetch_session, :protect_from_forgery]

      live_dashboard "/dashboard", metrics: FinpesWeb.Telemetry
      forward "/mailbox", Plug.Swoosh.MailboxPreview
    end
  end
end

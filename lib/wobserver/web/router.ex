defmodule Wobserver.Web.Router do
  @moduledoc ~S"""
  Main router.

  Splits into two paths:
    - `/api`, for all json api calls, handled by `Wobserver.Web.Router.Api`.
    - `/`, for all static assets, handled by `Wobserver.Web.Router.Static`.
  """

  use Plug.Router

  plug :match
  plug :dispatch

  forward "/api", to: Wobserver.Web.Router.Api
  forward "/metrics", to: Wobserver.Web.Router.Metrics
  forward "/", to: Wobserver.Web.Router.Static
end

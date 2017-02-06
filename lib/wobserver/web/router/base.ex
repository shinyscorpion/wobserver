defmodule Wobserver.Web.Router.Base do
  @moduledoc ~S"""
  Base Router module, includes standard helpers and plugs.
  """

  defmacro __using__(_opts) do
    quote do
      use Plug.Router

      import Wobserver.Web.Router.Helper, only: [send_json_resp: 2]

      plug :match
      plug :dispatch
    end
  end
end

defmodule Wobserver.Web.Router.Api do
  @moduledoc ~S"""
  Main api router.

  Returns the following resources:
    - `/about` => `Wobserver.about/0`.
    - `/nodes` => `Wobserver.NodeDiscovery.discover/0`.

  Splits into the following paths:
    - `/system`, for all system information, handled by `Wobserver.Web.Router.System`.

  All paths also include the option of entering a node name before the path.
  """

  use Wobserver.Web.Router.Base

  alias Plug.Router.Utils

  alias Wobserver.NodeDiscovery
  alias Wobserver.Web.Router.System

  match "/about" do
    Wobserver.about
    |> send_json_resp(conn)
  end

  match "/nodes" do
    NodeDiscovery.discover
    |> send_json_resp(conn)
  end

  match "/:node_name/system/*glob" do
    case NodeDiscovery.find(node_name) do
      :local ->
        Utils.forward(
          var!(conn),
          var!(glob),
          System,
          System.init([])
        )
      {:remote, _node} ->
        conn
        |> send_resp(501, "Remote node connections not implemented yet.")
      :unknown ->
        conn
        |> send_resp(404, "Node #{node_name} not Found")
    end
  end

  forward "/system", to: System

  match _ do
    conn
    |> send_resp(404, "Page not Found")
  end
end

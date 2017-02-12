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

  alias Wobserver.Allocator
  alias Wobserver.Page
  alias Wobserver.Table
  alias Wobserver.Util.Application
  alias Wobserver.Util.Process
  alias Wobserver.Util.Node.Discovery
  alias Wobserver.Util.Node.Remote
  alias Wobserver.Web.Router.Api
  alias Wobserver.Web.Router.System

  match "/nodes" do
    Discovery.discover
    |> send_json_resp(conn)
  end

  match "/custom" do
    Page.list
    |> send_json_resp(conn)
  end

  match "/about" do
    Wobserver.about
    |> send_json_resp(conn)
  end

  get "/application/:app" do
    app
    |> String.downcase
    |> String.to_atom
    |> Application.info
    |> send_json_resp(conn)
  end

  get "/application" do
    Application.list
    |> send_json_resp(conn)
  end

  get "/process" do
    Process.list
    |> send_json_resp(conn)
  end

  get "/process/:pid" do
    pid
    |> Process.info
    |> send_json_resp(conn)
  end

  get "/ports" do
    Wobserver.Port.list
    |> send_json_resp(conn)
  end

  get "/allocators" do
    Allocator.list
    |> send_json_resp(conn)
  end

  get "/table" do
    Table.list
    |> send_json_resp(conn)
  end

  get "/table/:table" do
    table
    |> Table.sanitize
    |> Table.info(true)
    |> send_json_resp(conn)
  end

  forward "/system", to: System

  match "/:node_name/*glob" do
    case glob do
      [] ->
        node_name
        |> String.to_atom
        |> Page.call
        |> send_json_resp(conn)
        # conn
        # |> send_resp(501, "Custom commands not implemented yet.")
      _ ->
        node_forward(node_name, conn, glob)
    end
  end

  match _ do
    conn
    |> send_resp(404, "Page not Found")
  end

  # Helpers

  defp node_forward(node_name, conn, glob) do
    case Discovery.find(node_name) do
      :local -> local_forward(conn, glob)
      {:remote, remote_node} -> remote_forward(remote_node, conn, glob)
      :unknown -> send_resp(conn, 404, "Node #{node_name} not Found")
    end
  end

  defp local_forward(conn, glob) do
    Utils.forward(
      var!(conn),
      var!(glob),
      Api,
      Api.init([])
    )
  end

  defp remote_forward(remote_node, conn, glob) do
    path =
      glob
      |> Enum.join

    case Remote.api(remote_node, "/" <>  path) do
      :error ->
        conn
        |> send_resp(500, "Node #{remote_node.name} not responding.")
      data ->
        conn
        |> put_resp_content_type("application/json")
        |> send_resp(200, data)
    end
  end
end

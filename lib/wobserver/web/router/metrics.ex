defmodule Wobserver.Web.Router.Metrics do
  @moduledoc ~S"""
  Metrics router.

  Returns the following resources:
    - `/` => All metrics for the local node.
    - `/memory` => Memory metrics for the local node.
    - `/io` => IO metrics for the local node.
  """

  use Wobserver.Web.Router.Base

  alias Wobserver.Util.Metrics
  alias Wobserver.Util.Metrics.Formatter
  alias Wobserver.Util.Node.Discovery
  alias Wobserver.Util.Node.Remote

  match "/" do
    data =
      Discovery.discover()
      |> Enum.map(&Remote.metrics/1)
      |> Formatter.merge_metrics()

    case data do
      :error -> send_resp(conn, 500, "Can not generate metrics.")
      _ -> send_resp(conn, 200, data)
    end
  end

  match "/n/:node_name" do
    case Discovery.find(node_name) do
      :local ->
        Metrics.overview()
        |> send_metrics(conn)

      {:remote, remote_node} ->
        data =
          remote_node
          |> Remote.metrics()

        case data do
          :error ->
            conn
            |> send_resp(500, "Node #{node_name} not responding.")

          result ->
            conn
            |> send_resp(200, result)
        end

      :unknown ->
        conn
        |> send_resp(404, "Node #{node_name} not Found")
    end
  end

  match "/memory" do
    Metrics.memory()
    |> send_metrics(conn)
  end

  match "/io" do
    Metrics.memory()
    |> send_metrics(conn)
  end

  match _ do
    conn
    |> send_resp(404, "Page not Found")
  end

  # Helpers

  defp send_metrics(data, conn) do
    case Formatter.format_all(data) do
      :error -> send_resp(conn, 500, "Can not generate metrics.")
      metrics -> send_resp(conn, 200, metrics)
    end
  end
end

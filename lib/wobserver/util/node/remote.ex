defmodule Wobserver.Util.Node.Remote do
  @moduledoc ~S"""
  Remote node.

  TODO: Needs config.
  """

  alias Wobserver.Web.ClientProxy
  alias Wobserver.Util.Metrics
  alias Wobserver.Util.Metrics.Formatter

  @typedoc "Remote node information."
  @type t :: %__MODULE__{
          name: String.t(),
          host: String.t(),
          port: integer,
          local?: boolean
        }

  defstruct [
    :name,
    :host,
    port: 4001,
    local?: false
  ]

  @remote_url_prefix Application.get_env(:wobserver, :remote_url_prefix, "")

  @spec call(map, endpoint :: String.t()) :: String.t() | :error
  defp call(%{host: host, port: port}, endpoint) do
    request =
      %URI{scheme: "http", host: host, port: port, path: endpoint}
      |> URI.to_string()
      |> HTTPoison.get()

    case request do
      {:ok, %{body: result}} -> result
      _ -> :error
    end
  end

  @doc ~S"""
  Collects metrics from a given `remote_node`.
  """
  @spec metrics(remote_node :: map) :: String.t() | :error
  def metrics(remote_node)

  def metrics(remote_node = %{local?: false}) do
    remote_node
    |> call("#{@remote_url_prefix}/metrics/n/local")
  end

  def metrics(%{local?: true}) do
    Metrics.overview()
    |> Formatter.format_all()
  end

  @doc ~S"""
  Performs an api call using the `path` on the `remote_node` and returns the result.
  """
  @spec api(remote_node :: map, path :: String.t()) :: String.t() | :error
  def api(remote_node, path) do
    remote_node
    |> call("#{@remote_url_prefix}/api" <> path)
  end

  @doc ~S"""
  Sets up a websocket connection to the given `remote_node`.
  """
  @spec socket_proxy(atom | map) :: {pid, String.t()} | {:error, String.t()}
  def socket_proxy(remote_node)

  def socket_proxy(%{local?: true}), do: socket_proxy(:local)

  def socket_proxy(%{name: name, host: host, port: port}) do
    connection =
      %URI{scheme: "ws", host: host, port: port, path: "#{@remote_url_prefix}/ws"}
      |> URI.to_string()
      |> ClientProxy.connect()

    case connection do
      {:ok, pid} -> {pid, name}
      _ -> {:error, "Can not connect to node."}
    end
  end

  def socket_proxy(type) do
    case type do
      :local -> {nil, "local"}
      {:remote, remote_node} -> socket_proxy(remote_node)
      _ -> {:error, "Can not find node."}
    end
  end
end

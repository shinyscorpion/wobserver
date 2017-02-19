defmodule Wobserver.Web.ClientProxy do
  @moduledoc ~S"""
  ClientProxy will proxy websocket requests from `Wobserver.Web.ClientSocket` to a remote node.

  TODO: Needs config.
  """

  @behaviour :websocket_client

  @doc false
  @spec connect(url :: String.t, client :: pid) ::
    {:ok, pid}
    | any
  def connect(url, client \\ self()) do
    connect =
      try do
        :websocket_client.start_link(url, __MODULE__, [%{client: client}])
      catch
        error -> error
      end

    case connect do
      {:ok, pid} ->
        Process.unlink pid

        {:ok, pid}
      error ->
        error
    end
  end

  @doc false
  @spec init(state :: [any]) :: {:reconnect, map}
  def init([state]) do
    {:reconnect, state}
  end

  @doc false
  @spec onconnect(any, state :: map) :: {:ok, map}
  def onconnect(_websocket_request, state) do
    {:ok, state}
  end

  @doc false
  @spec ondisconnect(any, state :: map) :: {:close, any, map}
  def ondisconnect(reason, state) do
    send state.client, :proxy_disconnect

    {:close, reason, state}
  end

  @doc false
  @spec websocket_info({:proxy, data :: String.t}, any, state :: map) ::
    {:reply, {:text, String.t}, map}
  def websocket_info({:proxy, data}, _connection, state) do
    {:reply, {:text, data}, state}
  end

  @spec websocket_info(:disconnect, any, state :: map) ::
    {:close, String.t, map}
  def websocket_info(:disconnect, _connection, state) do
    {:close, "Disconnect", state}
  end

  @doc false
  @spec websocket_terminate(any, any, map) :: :ok
  def websocket_terminate(_reason, _conn, _state), do: :ok

  @doc false
  @spec websocket_handle(any, any, state :: map) :: {:ok, map}
  def websocket_handle(message, conn, state)

  def websocket_handle({:text, message}, _conn, state) do
    send state.client, {:proxy, message}
    {:ok, state}
  end

  def websocket_handle(_, _conn, state), do: {:ok, state}
end

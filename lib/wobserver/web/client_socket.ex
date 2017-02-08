defmodule Wobserver.Web.ClientSocket do
  @moduledoc ~S"""
  Low level WebSocket handler

  Connects to the Javascript websocket and parses all requests.

  Example:
    ```elixir
    defmodule Wobserver.Web.Client do
      use Wobserver.Web.ClientSocket

      alias Wobserver.System

      def client_init do
        {:ok, %{}}
      end

      def client_handle(:hello, state) do
        {:reply, :ehlo, state}
      end

      def client_info(:update, state) do
        {:noreply, state}
      end
    end
    ```
  """

  require Logger

  alias Wobserver.Util.Node.Discovery
  alias Wobserver.Util.Node.Remote
  alias Wobserver.Web.ClientSocket

  @typedoc "Response to browser."
  @type response ::
    {:reply, atom, any, any}
    | {:reply, atom, any}
    | {:noreply, any}

  @doc ~S"""
  Initalizes the WebSocket.

  Return {`:ok`, initial state} or {`:ok`, initial state, socket timeout}.
  """
  @callback client_init :: {:ok, any} | {:ok, any, non_neg_integer}
  @doc ~S"""
  Handles messages coming from the WS client.

  Return browser response.
  """
  @callback client_handle(atom | {atom, any}, any) :: ClientSocket.response
  @doc ~S"""
  Handles messages coming from other processes.

  Return browser response.
  """
  @callback client_info(any, any) :: ClientSocket.response

  defmacro __using__(_) do
    quote do
      import Wobserver.Web.ClientSocket, only: :functions

      @behaviour :cowboy_websocket_handler
      @behaviour Wobserver.Web.ClientSocket

      @timeout 60_000

      # Callbacks

      ## Init / Shutdown
      @spec init(any, :cowboy_req.req, any) ::
        {:upgrade, :protocol, :cowboy_websocket}
      def init(_, _req, _opts) do
        {:upgrade, :protocol, :cowboy_websocket}
      end

      @spec websocket_init(any, req :: :cowboy_req.req, any) ::
        {:ok, :cowboy_req.req, any, non_neg_integer}
      def websocket_init(_type, req, _opts) do
        case client_init() do
          {:ok, state, timeout} ->
            {:ok, req, %{state: state, proxy: nil}, timeout}
          {:ok, state} ->
            {:ok, req, %{state: state, proxy: nil}, @timeout}
        end
      end

      @spec websocket_terminate({atom, any}, :cowboy_req.req, any) :: :ok
      def websocket_terminate(_reason, _req, _state) do
        :ok
      end

      ## Incoming from client / browser
      @spec websocket_handle(
        {:text, String.t},
        req :: :cowboy_req.req,
        state :: any
      ) :: {:reply, {:text, String.t}, :cowboy_req.req, any}
        | {:ok, :cowboy_req.req, any}
      def websocket_handle(message, req, state)

      def websocket_handle({:text, command}, req, state = %{proxy: nil}) do
        case parse_command(command) do
          {:setup_proxy, name} ->
            setup_proxy(name, state, req)
          :nodes ->
            {:reply, :nodes, Discovery.discover, state.state}
            |> send_response(state, req)
          parsed_command ->
            parsed_command
            |> client_handle(state.state)
            |> send_response(state, req)
        end
      end

      def websocket_handle({:text, command}, req, state) do
        case parse_command(command) do
          {:setup_proxy, name} ->
            setup_proxy(name, state, req)
          :nodes ->
            {:reply, :nodes, Discovery.discover, state.state}
            |> send_response(state, req)
          parsed_command ->
            send state.proxy, {:proxy, command}
            {:ok, req, state}
        end
      end

      ## Outgoing
      @spec websocket_info(
        message :: any,
        req :: :cowboy_req.req,
        state :: any
      ) :: {:reply, {:text, String.t}, :cowboy_req.req, any}
        | {:ok, :cowboy_req.req, any}
      def websocket_info(message, req, state)

      def websocket_info({:proxy, data}, req, state) do
        {:reply, {:text, data}, req, state}
      end

      def websocket_info(:proxy_disconnect, req, state) do
        {:reply, :proxy_disconnect, state.state, req}
        |> send_response(%{state | proxy: nil}, req)
      end

      def websocket_info(message, req, state) do
        message
        |> client_info(state.state)
        |> send_response(state, req)
      end
    end
  end

  # Helpers

  ## Command
  @spec parse_command(payload :: String.t) :: atom | {atom, any}
  def parse_command(payload) do
    command_data = Poison.decode!(payload)

    command = command_data["command"] |> String.to_atom

    case command_data["data"] do
      "" -> command
      nil -> command
      data -> {command, data}
    end
  end

  @spec send_response(
    message ::  {:noreply, any}
              | {:reply, atom, any}
              | {:reply, atom, map | list | String.t | nil, any},
    socket_state :: map,
    req :: :cowboy_req.req
  ) ::
    {:reply, {:text, String.t}, :cowboy_req.req, map}
    | {:ok, :cowboy_req.req, map}
  def send_response(message, socket_state, req)

  def send_response({:noreply, state}, socket_state, req) do
    {:ok, req, %{socket_state | state: state}}
  end

  def send_response({:reply, type, message, state}, socket_state, req) do
    data = %{
      type: type,
      timestamp: :os.system_time(:seconds),
      data: message,
    }

    case Poison.encode(data) do
      {:ok, payload} ->
        {:reply, {:text, payload}, req, %{socket_state | state: state}}
      {:error, error} ->
        Logger.warn "Wobserver.Web.ClientSocket: Can't send message #{inspect message}, reason: #{inspect error}"

        {:ok, req, %{socket_state | state: state}}
    end
  end

  def send_response({:reply, type, state}, socket_state, req) do
    send_response({:reply, type, nil, state}, socket_state, req)
  end

  @spec setup_proxy(proxy :: String.t, state :: map, req :: :cowboy_req.req) ::
    {:reply, {:text, String.t}, :cowboy_req.req, map}
    | {:ok, :cowboy_req.req, map}
  def setup_proxy(proxy, state, req) do
    connected =
      proxy
      |> Discovery.find
      |> Remote.socket_proxy

    case connected do
      {:error, message} ->
        {:reply, :setup_proxy, %{error: message}, state.state}
        |> send_response(state, req)
      {pid, "local"} ->
        if state.proxy != nil, do: send state.proxy, :disconnect

        name = Discovery.local.name

        {
          :reply,
          :setup_proxy,
          %{success: "Connected to: #{name}", node: name},
          state.state
        }
        |> send_response(%{state | proxy: pid}, req)
      {pid, name} ->
        {
          :reply,
          :setup_proxy,
          %{success: "Connected to: #{name}", node: name},
          state.state
        }
        |> send_response(%{state | proxy: pid}, req)
    end
  end
end

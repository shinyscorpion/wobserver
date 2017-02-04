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
      require Logger

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
          {:ok, state, timeout} -> {:ok, req, state, timeout}
          {:ok, state} -> {:ok, req, state, @timeout}
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
      def websocket_handle({:text, command}, req, state) do
        command
        |> parse_command
        |> client_handle(state)
        |> send_response(req)
      end

      ## Outgoing
      @spec websocket_info(
        message :: any,
        req :: :cowboy_req.req,
        state :: any
      ) :: {:reply, {:text, String.t}, :cowboy_req.req, any}
        | {:ok, :cowboy_req.req, any}
      def websocket_info(message, req, state) do
        message
        |> client_info(state)
        |> send_response(req)
      end

      # Helpers

      ## Command
      defp parse_command(payload) do
        command_data = Poison.decode!(payload)

        command = command_data["command"] |> String.to_atom

        case command_data["data"] do
          "" -> command
          nil -> command
          data -> {command, data}
        end
      end

      defp send_response({:noreply, state}, req) do
        {:ok, req, state}
      end

      defp send_response({:reply, type, message, state}, req) do
        data = %{
          type: type,
          timestamp: :os.system_time(:seconds),
          data: message,
        }

        case Poison.encode(data) do
          {:ok, payload} ->
            {:reply, {:text, payload}, req, state}
          {:error, error} ->
            Logger.warn "Wobserver.Web.ClientSocket: Can't send message #{inspect message}, reason: #{inspect error}"

            {:ok, req, state}
        end
      end

      defp send_response({:reply, type, state}, req) do
        send_response({:reply, type, nil, state}, req)
      end
    end
  end
end

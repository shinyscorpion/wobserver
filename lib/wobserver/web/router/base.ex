defmodule Wobserver.Web.Router.Base do
  @moduledoc ~S"""
  Base Router module, includes standard helpers and plugs.
  """

  defmacro __using__(_opts) do
    quote do
      use Plug.Router

      @doc false
      @spec init(opts :: Plug.opts()) :: Plug.opts()
      def init(opts) do
        opts
      end

      @doc false
      @spec call(conn :: Plug.Conn.t(), opts :: Plug.opts()) :: Plug.Conn.t()
      def call(conn, opts) do
        plug_builder_call(conn, opts)
      end

      import Wobserver.Web.Router.Helper, only: [send_json_resp: 2]

      plug(:match)
      plug(:dispatch)
    end
  end
end

defmodule Wobserver.Application do
  @moduledoc ~S"""
  Sets up the main routers with Cowboy.
  """

  use Application

  alias Plug.Adapters.Cowboy

  alias Wobserver.Page
  alias Wobserver.Util.Metrics

  @spec port :: integer
  def port do
    Application.get_env(:wobserver, :port, 4001)
  end

  @spec start(term, term) ::
    {:ok, pid} |
    {:ok, pid, state :: any} |
    {:error, reason :: term}
  def start(_type, _args) do
    # Load pages and metrics from config
    Page.load_config
    Metrics.load_config

    # Start cowboy
    import Supervisor.Spec, warn: false

    children = [
      cowboy_child_spec(),
    ]

    opts = [strategy: :one_for_one, name: Wobserver.Supervisor]
    Supervisor.start_link(children, opts)
  end

  defp cowboy_child_spec do
    options = [
      # Options
      acceptors: 10,
      port: Wobserver.Application.port,
      dispatch: [
        {:_, [
          {"/ws", Wobserver.Web.Client, []},
          {:_, Cowboy.Handler, {Wobserver.Web.Router, []}}
        ]}
      ],
    ]

    Cowboy.child_spec(:http, Wobserver.Web.Router, [], options)
  end
end

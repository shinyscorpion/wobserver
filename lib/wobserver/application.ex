defmodule Wobserver.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      # Starts a worker by calling: Wobserver.Worker.start_link(arg1, arg2, arg3)
      # worker(Wobserver.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Wobserver.Supervisor]
    Supervisor.start_link(children, opts)
  end
end

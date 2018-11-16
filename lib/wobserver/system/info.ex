defmodule Wobserver.System.Info do
  @moduledoc ~S"""
  Handles general System info like architecture and cpu.
  """

  alias Wobserver.System.Info

  @typedoc ~S"""
  Architecture information.
  """
  @type t :: %__MODULE__{
          otp_release: String.t(),
          elixir_version: String.t(),
          erts_version: String.t(),
          system_architecture: String.t(),
          kernel_poll: boolean,
          smp_support: boolean,
          threads: boolean,
          thread_pool_size: integer,
          wordsize_internal: integer,
          wordsize_external: integer
        }

  defstruct otp_release: "",
            elixir_version: "",
            erts_version: "",
            system_architecture: "",
            kernel_poll: false,
            smp_support: false,
            threads: false,
            thread_pool_size: 0,
            wordsize_internal: 0,
            wordsize_external: 0

  @doc ~S"""
  Returns architecture information.
  """
  @spec architecture :: Info.t()
  def architecture do
    %Info{
      otp_release: to_string(:erlang.system_info(:otp_release)),
      elixir_version: System.version(),
      erts_version: to_string(:erlang.system_info(:version)),
      system_architecture: to_string(:erlang.system_info(:system_architecture)),
      kernel_poll: :erlang.system_info(:kernel_poll),
      smp_support: :erlang.system_info(:smp_support),
      threads: :erlang.system_info(:threads),
      thread_pool_size: :erlang.system_info(:thread_pool_size),
      wordsize_internal: :erlang.system_info({:wordsize, :internal}),
      wordsize_external: :erlang.system_info({:wordsize, :internal})
    }
  end

  @doc ~S"""
  Returns cpu information.
  """
  def cpu do
    schedulers = :erlang.system_info(:logical_processors)

    schedulers_available =
      case :erlang.system_info(:multi_scheduling) do
        :enabled -> schedulers
        _ -> 1
      end

    %{
      logical_processors: :erlang.system_info(:logical_processors),
      logical_processors_online: :erlang.system_info(:logical_processors_online),
      logical_processors_available: :erlang.system_info(:logical_processors_available),
      schedulers: :erlang.system_info(:schedulers),
      schedulers_online: schedulers,
      schedulers_available: schedulers_available
    }
  end
end

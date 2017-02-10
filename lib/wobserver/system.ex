defmodule Wobserver.System do
  @moduledoc ~S"""
  Provides System information.
  """

  alias Wobserver.System.Info
  alias Wobserver.System.Memory
  alias Wobserver.System.Scheduler
  alias Wobserver.System.Statistics

  @typedoc ~S"""
  System overview information.

  Including:
    - `architecture`, architecture information.
    - `cpu`, cpu information.
    - `memory`, memory usage.
    - `statistics`, general System statistics.
    - `scheduler`, scheduler utilization per scheduler.
  """
  @type t :: %__MODULE__{
    architecture: Info.t,
    cpu: map,
    memory: Memory.t,
    statistics: Statistics.t,
    scheduler: list(float)
  }

  defstruct [
    :architecture,
    :cpu,
    :memory,
    :statistics,
    :scheduler,
  ]

  @doc ~S"""
  Provides a overview of all System information.

  Including:
    - `architecture`, architecture information.
    - `cpu`, cpu information.
    - `memory`, memory usage.
    - `statistics`, general System statistics.
    - `scheduler`, scheduler utilization per scheduler.
  """
  @spec overview :: Wobserver.System.t
  def overview do
    %__MODULE__{
      architecture: Info.architecture,
      cpu: Info.cpu,
      memory: Memory.usage,
      statistics: Statistics.overview,
      scheduler: Scheduler.utilization,
    }
  end
end

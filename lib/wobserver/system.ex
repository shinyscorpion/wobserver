defmodule Wobserver.System do
  @moduledoc ~S"""
  Provides System information.
  """

  alias Wobserver.System.{
    Info,
    Memory,
    Statistics,
  }

  @typedoc ~S"""
  Memory information.
  """
  @type t :: %__MODULE__{
    architecture: Info.t,
    cpu: map,
    memory: Memory.t,
    statistics: Statistics.t,
  }

  defstruct [
    :architecture,
    :cpu,
    :memory,
    :statistics,
  ]

  @doc ~S"""
  Provides a overview of all System information.

  Including:
    - `architecture`, architecture information.
    - `cpu`, cpu information.
    - `memory`, memory usage.
    - `statistics`, general System statistics.
  """
  @spec overview :: Wobserver.System.t
  def overview do
    %__MODULE__{
      architecture: Info.architecture,
      cpu: Info.cpu,
      memory: Memory.usage,
      statistics: Statistics.overview,
    }
  end
end

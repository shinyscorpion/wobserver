defmodule Wobserver.System.Memory do
  @moduledoc ~S"""
  Handles memory information.
  """

  @typedoc ~S"""
  Memory information.
  """
  @type t :: %__MODULE__{
          atom: integer,
          binary: integer,
          code: integer,
          ets: integer,
          process: integer,
          total: integer
        }

  defstruct atom: 0,
            binary: 0,
            code: 0,
            ets: 0,
            process: 0,
            total: 0

  @doc ~S"""
  Returns memory usage.
  """
  @spec usage :: Wobserver.System.Memory.t()
  def usage do
    mem = :erlang.memory()

    %__MODULE__{
      atom: Keyword.get(mem, :atom),
      binary: Keyword.get(mem, :binary),
      code: Keyword.get(mem, :code),
      ets: Keyword.get(mem, :ets),
      process: Keyword.get(mem, :processes),
      total: Keyword.get(mem, :total)
    }
  end
end

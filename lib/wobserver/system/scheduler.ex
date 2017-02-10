defmodule Wobserver.System.Scheduler do
  @moduledoc ~S"""
  Scheduler

  TODO:
    - Needs docs.
    - Needs cleanup.
    - Needs tests.
  """

  @table :wobserver_scheduler
  @lookup_key :last_utilization

  @spec utilization :: list(float)
  def utilization do
    ensure_started()

    case last_utilization() do
      false ->
        get_utilization()
        |> Enum.map(fn {_, u, t} -> u / t end)
      last ->
        get_utilization()
        |> Enum.zip(last)
        |> Enum.map(fn {{_, u0, t0}, {_, u1, t1}} -> (u1 - u0) / (t1 - t0) end)
    end
  end

  defp get_utilization do
    util =
      :scheduler_wall_time
      |> :erlang.statistics
      |> :lists.sort()

    :ets.insert @table, {@lookup_key, util}

    util
  end

  defp last_utilization do
    case :ets.lookup(@table, @lookup_key) do
      [{@lookup_key, util}] -> util
      _ -> false
    end
  end

  defp ensure_started do
    case :ets.info(@table) do
      :undefined ->
        :erlang.system_flag(:scheduler_wall_time, true)
        :ets.new @table, [:named_table, :public]
      _ ->
        true
    end
  end
end

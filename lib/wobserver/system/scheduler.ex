defmodule Wobserver.System.Scheduler do
  @moduledoc ~S"""
  Scheduler utilization per scheduler.

  Example:
  ```bash
  Wobserver.System.Scheduler.utilization
  [1.0, 0.0306945631032665, 0.03640598025269633, 0.05220935570330663,
   0.04884165187164101, 0.08352432821297966, 0.11547042454628796,
   0.2861211090456038]
  ```
  """

  @table :wobserver_scheduler
  @lookup_key :last_utilization

  @doc ~S"""
  Calculates scheduler utilization per scheduler.

  Returns a list of floating point values range (0-1) indicating 0-100% utlization.

  Example:
  ```bash
  Wobserver.System.Scheduler.utilization
  [1.0, 0.0306945631032665, 0.03640598025269633, 0.05220935570330663,
   0.04884165187164101, 0.08352432821297966, 0.11547042454628796,
   0.2861211090456038]
  ```
  """
  @spec utilization :: list(float)
  def utilization do
    ensure_started()

    case last_utilization() do
      false ->
        get_utilization()
        |> Enum.map(fn {_, u, t} -> percentage(u, t) end)
      last ->
        get_utilization()
        |> Enum.zip(last)
        |> Enum.map(fn {{_, u0, t0}, {_, u1, t1}} -> percentage((u1 - u0), (t1 - t0)) end)
    end
  end

  defp percentage(_, 0), do: 0
  defp percentage(u, t), do: u / t

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

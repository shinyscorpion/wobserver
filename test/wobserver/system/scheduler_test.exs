defmodule Wobserver.System.SchedulerTest do
  use ExUnit.Case

  alias Wobserver.System.Scheduler

  test "returns results as list" do
    assert is_list(Scheduler.utilization())
  end

  test "returns results as list of floats" do
    all_floats =
      Scheduler.utilization()
      |> Enum.map(&is_float/1)
      |> Enum.reduce(&Kernel.and/2)

    assert all_floats
  end

  test "returns results querying multiple times" do
    assert is_list(Scheduler.utilization())
    assert is_list(Scheduler.utilization())
  end
end

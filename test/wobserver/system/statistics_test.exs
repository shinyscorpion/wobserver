defmodule Wobserver.System.StatisticsTest do
  use ExUnit.Case

  describe "overview" do
    test "returns statistics struct" do
      assert %Wobserver.System.Statistics{} = Wobserver.System.Statistics.overview
    end

    test "returns values" do
      %Wobserver.System.Statistics{
        uptime: uptime,
        process_running: process_running,
        process_total: process_total,
        process_max: process_max,
        input: input,
        output: output,
      } = Wobserver.System.Statistics.overview

      assert uptime > 0
      assert process_running >= 0
      assert process_total > 0
      assert process_max > 0
      assert input >= 0
      assert output >= 0
    end
  end
end

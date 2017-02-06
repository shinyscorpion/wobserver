defmodule Wobserver.SystemTest do
  use ExUnit.Case

  describe "overview" do
    test "returns system struct" do
      assert %Wobserver.System{} = Wobserver.System.overview
    end

    test "returns values" do
      %Wobserver.System{
        architecture: architecture,
        cpu: cpu,
        memory: memory,
        statistics: statistics,
      } = Wobserver.System.overview

      assert architecture
      assert cpu
      assert memory
      assert statistics
    end
  end
end

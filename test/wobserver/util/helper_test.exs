defmodule Wobserver.Util.HelperTest do
  use ExUnit.Case

  alias Wobserver.Util.Helper
  alias Wobserver.Util.Process

  describe "string_to_module" do
    test "returns module name without dots" do
      assert Helper.string_to_module("Logger") == Logger
    end

    test "returns module name with dots" do
      assert Helper.string_to_module("Logger.Supervisor") == Logger.Supervisor
    end

    test "returns atom" do
      assert Helper.string_to_module("atom") == :atom
    end

    test "returns atom with spaces" do
      assert Helper.string_to_module("has spaces") == :"has spaces"
    end
  end

  describe "JSON implementations" do
    test "PID" do
      pid = Process.pid(33);
      encoder = Poison.Encoder.impl_for(pid)

      assert encoder.encode(pid, []) == [34, ["#PID<0.33.0>"], 34]
    end

    test "Port" do
      port = :erlang.ports |> List.first
      encoder = Poison.Encoder.impl_for(port)

      assert encoder.encode(port, []) == [34, ["#Port<0.0>"], 34]
    end
  end

  describe "format_function" do
    test "nil" do
      assert Helper.format_function(nil) == nil
    end

    test "with function typle" do
      assert Helper.format_function({Logger, :log, 2}) == "Elixir.Logger.log/2"
    end

    test "returns function atom" do
      assert Helper.format_function(:format_function) == "format_function"
    end
  end

  describe "parallel_map" do
    test "maps" do
      assert Helper.parallel_map([1, 2, 3], fn x -> x * 2 end) == [2, 4, 6]
    end
  end
end

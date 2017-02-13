defmodule Wobserver.Util.MetricsTest do
  use ExUnit.Case

  alias Wobserver.Util.Metrics

  describe "overview" do
    test "returns a list" do
      assert is_list(Metrics.overview)
    end

    test "returns a keyword list" do
      assert Keyword.keyword?(Metrics.overview)
    end
  end

  describe "register" do
    test "registers a metric" do
      assert Metrics.register [example: {fn -> [{5, []}] end, :gauge, "Description"}]

      assert Keyword.has_key?(Metrics.overview, :example)
    end

    test "registers a metric generator" do
      assert Metrics.register [
        fn -> [generated: {fn -> [{5, []}] end, :gauge, "Description"}] end
      ]

      assert Keyword.has_key?(Metrics.overview, :generated)
    end

    test "registers a string metric generator" do
      assert Metrics.register [
        "fn -> [generated_s: {fn -> [{5, []}] end, :gauge, \"Description\"}] end"
      ]

      assert Keyword.has_key?(Metrics.overview, :generated_s)
    end
  end

  describe "load_config" do
    setup do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :metrics -> [
            additional: [config_example: {fn -> [{5, []}] end, :gauge, "Description"}],
            generators: [fn -> [config_generated: {fn -> [{5, []}] end, :gauge, "Description"}] end]
          ]
          :discovery -> :none
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      Metrics.load_config

      :ok
    end

    test "loads metric from config" do
      assert Keyword.has_key?(Metrics.overview, :config_example)
    end
    test "loads generated metrics from config" do
      assert Keyword.has_key?(Metrics.overview, :config_generated)
    end
  end
end

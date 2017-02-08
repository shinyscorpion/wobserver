defmodule Wobserver.Util.Metrics.PrometheusTest do
  use ExUnit.Case, async: false

  alias Wobserver.Util.Metrics.Prometheus

  describe "merge_metrics" do
    test "removes duplicate help" do
      assert Prometheus.merge_metrics([
        "# HELP double Bla bla\n",
        "# HELP double Bla bla\n",
      ]) == "# HELP double Bla bla\n"
    end

    test "removes duplicate type" do
      assert Prometheus.merge_metrics([
        "# TYPE double gauge\n",
        "# TYPE double gauge\n",
      ]) == "# TYPE double gauge\n"
    end
  end
end

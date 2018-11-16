defmodule Wobserver.Util.Metrics.FormatterTest do
  use ExUnit.Case, async: false

  alias Wobserver.Util.Metrics.{
    Formatter,
    Prometheus
  }

  def example_function do
    [point: 5]
  end

  def local_ip do
    with {:ok, ips} <- :inet.getif(),
         {ip, _, _} <- List.first(ips),
         {ip1, ip2, ip3, ip4} <- ip,
         do: "#{ip1}.#{ip2}.#{ip3}.#{ip4}"
  end

  describe "format" do
    test "returns with valid data" do
      assert Formatter.format(
               %{point: 5},
               "data"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data and type" do
      assert Formatter.format(
               %{point: 5},
               "data",
               :gauge
             ) == "# TYPE data gauge\ndata{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data, type, and help" do
      assert Formatter.format(
               %{point: 5},
               "data",
               :gauge,
               "help"
             ) ==
               "# HELP data help\n# TYPE data gauge\ndata{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data as integer" do
      assert Formatter.format(
               5,
               "data"
             ) == "data{node=\"#{local_ip()}\"} 5\n"
    end

    test "returns with valid data as float" do
      assert Formatter.format(
               5.4,
               "data"
             ) == "data{node=\"#{local_ip()}\"} 5.4\n"
    end

    test "returns with valid data as keywords" do
      assert Formatter.format(
               [point: 5],
               "data"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data as data String" do
      assert Formatter.format(
               "[point: 5]",
               "data"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data as anon function" do
      assert Formatter.format(
               "fn -> [point: 5] end",
               "data"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data as function call" do
      assert Formatter.format(
               "Wobserver.Util.Metrics.FormatterTest.example_function",
               "data"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with valid data as function" do
      assert Formatter.format(
               "&Wobserver.Util.Metrics.FormatterTest.example_function/0",
               "data"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with explicit formatter" do
      assert Formatter.format(
               [point: 5],
               "data",
               nil,
               nil,
               Wobserver.Util.Metrics.Prometheus
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end

    test "returns with explicit formatter as String" do
      assert Formatter.format(
               [point: 5],
               "data",
               nil,
               nil,
               "Wobserver.Util.Metrics.Prometheus"
             ) == "data{node=\"#{local_ip()}\",type=\"point\"} 5\n"
    end
  end

  describe "format_all" do
    test "returns :error with invalid entry" do
      assert Formatter.format_all(
               works: %{value: 8},
               invalid: "w{"
             ) == :error
    end

    test "returns with multiple entries" do
      assert Formatter.format_all(
               [
                 works: %{value: 8},
                 also_works: %{value: 9}
               ],
               Prometheus
             ) ==
               "works{node=\"#{local_ip()}\",type=\"value\"} 8\nalso_works{node=\"#{local_ip()}\",type=\"value\"} 9\n"
    end

    test "returns with multiple entries and type" do
      assert Formatter.format_all(
               [
                 works: {
                   %{value: 8},
                   :gauge
                 },
                 also_works: %{value: 9}
               ],
               Prometheus
             ) ==
               "# TYPE works gauge\nworks{node=\"#{local_ip()}\",type=\"value\"} 8\nalso_works{node=\"#{
                 local_ip()
               }\",type=\"value\"} 9\n"
    end

    test "returns with multiple entries + type & help" do
      assert Formatter.format_all(
               [
                 works: {
                   %{value: 8},
                   :gauge,
                   "Info"
                 },
                 also_works: %{value: 9}
               ],
               Prometheus
             ) ==
               "# HELP works Info\n# TYPE works gauge\nworks{node=\"#{local_ip()}\",type=\"value\"} 8\nalso_works{node=\"#{
                 local_ip()
               }\",type=\"value\"} 9\n"
    end
  end
end

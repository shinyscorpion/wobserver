defmodule Wobserver.Util.Metrics.Prometheus do
  @moduledoc ~S"""
  Prometheus formatter.

  Formats metrics in a for Prometheus readable way.
  See: [https://prometheus.io/docs/instrumenting/writing_exporters/](https://prometheus.io/docs/instrumenting/writing_exporters/)
  """

  @behaviour Wobserver.Util.Metrics.Formatter

  @doc ~S"""
  Format a set of `data` with a `label` for a Prometheus.

  The `data` must be given as a `list` of tuples with the following format: `{value, labels}`, where `labels` is a keyword list with labels and their values.

  The following options can also be given:
    - `type`, the type of the metric. The following values are currently supported: `:gauge`, `:counter`.
    - `help`, a single line text description of the metric.
  """
  @spec format_data(
          name :: String.t(),
          data :: [{integer | float, keyword}],
          type :: :atom,
          help :: String.t()
        ) :: String.t()
  def format_data(name, data, type, help) do
    "#{format_help(name, help)}#{format_type(name, type)}#{format_values(name, data)}"
  end

  @doc ~S"""
  Combines formatted metrics together.

  Arguments:
    - `metrics`, a list of formatted metrics for one node.

  Example:
      iex> combine_metrics ["metric1{node="127.0.0.1"} 5\n", "metric2{node="127.0.0.1"} 5\n"]
      "metric1{node="127.0.0.1"} 5\n", "metric2{node="127.0.0.1"} 5\n"
  """
  @spec combine_metrics(metrics :: list[String.t()]) :: String.t()
  def combine_metrics(metrics), do: Enum.join(metrics)

  @doc ~S"""
  Merges formatted sets of metrics from different nodes together.

  The merge will filter out double declarations of help and type.

  Arguments:
    - `metrics`, a list of formatted sets metrics for multiple node.

  Example:
      iex> combine_metrics ["metric{node="192.168.0.6"} 5\n", "metric{node="192.168.0.5"} 5\n"]
      "metric{node="192.168.0.6"} 5\n", "metric{node="192.168.0.7"} 5\n"
  """
  @spec merge_metrics(metrics :: list[String.t()]) :: String.t()
  def merge_metrics(metrics) do
    {combined, _} = Enum.reduce(metrics, {"", []}, &filter/2)

    combined
  end

  # Helpers

  defp format_help(_name, nil), do: ""

  defp format_help(name, help) do
    "\# HELP #{name} #{help}\n"
  end

  defp format_type(_name, nil), do: ""

  defp format_type(name, type) do
    "\# TYPE #{name} #{type}\n"
  end

  defp format_labels(labels) do
    labels
    |> Enum.map(fn {label, value} -> "#{label}=\"#{value}\"" end)
    |> Enum.join(",")
  end

  defp format_values(name, data) do
    data
    |> Enum.map(fn {value, labels} -> "#{name}{#{format_labels(labels)}} #{value}\n" end)
    |> Enum.join()
  end

  defp analyze_metrics(metrics) do
    help =
      ~r/^\# HELP ([a-zA-Z_]+\ )/m
      |> Regex.scan(metrics)
      |> Enum.map(fn [match | _] -> match end)

    type =
      ~r/^\# TYPE ([a-zA-Z_]+\ )/m
      |> Regex.scan(metrics)
      |> Enum.map(fn [match | _] -> match end)

    help ++ type
  end

  defp filter_line(line, filter) do
    filter
    |> Enum.find_value(false, &String.starts_with?(line, &1))
    |> Kernel.!()
  end

  defp filter(metric, {metrics, filter}) do
    filtered_metric =
      metric
      |> String.split("\n")
      |> Enum.filter(&filter_line(&1, filter))
      |> Enum.join("\n")

    updated_filter =
      filtered_metric
      |> analyze_metrics()
      |> Kernel.++(filter)

    {metrics <> filtered_metric, updated_filter}
  end
end

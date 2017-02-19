defmodule Wobserver.Util.Metrics.Formatter do
  @moduledoc ~S"""
  Formatter.
  """

  alias Wobserver.Util.Node.Discovery

  @doc ~S"""
  Format a set of `data` with a `label`.

  The `data` must be given as a `list` of tuples with the following format: `{value, labels}`, where `labels` is a keyword list with labels and their values.

  The following options can also be given:
    - `type`, the type of the metric. The following values are currently supported: `:gauge`, `:counter`.
    - `help`, a single line text description of the metric.
  """
  @callback format_data(
    name :: String.t,
    data :: [{integer | float, keyword}],
    type :: :atom,
    help :: String.t
  ) :: String.t

  @doc ~S"""
  Combines formatted metrics together.

  Arguments:
    - `metrics`, a list of formatted metrics for one node.
  """
  @callback combine_metrics(
    metrics :: list[String.t]
  ) :: String.t

  @doc ~S"""
  Merges formatted sets of metrics from different nodes together.

  The merge should prevent double declarations of help and type.

  Arguments:
    - `metrics`, a list of formatted sets metrics for multiple node.
  """
  @callback merge_metrics(
    metrics :: list[String.t]
  ) :: String.t

  @doc ~S"""
  Format a set of `data` with a `label` for a metric parser/aggregater.

  The following options can also be given:
    - `type`, the type of the metric. The following values are currently supported: `:gauge`, `:counter`.
    - `help`, a single line text description of the metric.
    - `formatter`, a module implementing the `Formatter` behaviour to format metrics.
  """
  @spec format(
    data :: any,
    label :: String.t,
    type :: :gauge | :counter | nil,
    help :: String.t | nil,
    formatter :: atom | nil
  ) :: String.t | :error
  def format(data, label, type \\ nil, help \\ nil, formatter \\ nil)

  def format(data, label, type, help, nil) do
    format(data, label, type, help, Application.get_env(
      :wobserver,
      :metric_format,
      Wobserver.Util.Metrics.Prometheus
    ))
  end

  def format(data, label, type, help, formatter) when is_binary(formatter) do
    {new_formatter, []} = Code.eval_string formatter

    format(data, label, type, help, new_formatter)
  end

  def format(data, label, type, help, formatter)
  when is_integer(data) or is_float(data) do
    format([{data, []}], label, type, help, formatter)
  end

  def format(data, label, type, help, formatter) when is_map(data) do
    data
    |> map_to_data()
    |> format(label, type, help, formatter)
  end

  def format(data, label, type, help, formatter) when is_binary(data) do
    {new_data, []} = Code.eval_string data

    format(new_data, label, type, help, formatter)
  catch
    :error, _ -> :error
  end

  def format(data, label, type, help, formatter) when is_function(data) do
    data.()
    |> format(label, type, help, formatter)
  end

  def format(data, label, type, help, formatter) do
    cond do
      Keyword.keyword?(data) ->
        data
        |> list_to_data()
        |> format(label, type, help, formatter)
      is_list(data) ->
        data =
          data
          |> Enum.map(fn {value, labels} ->
              {value, Keyword.merge([node: Discovery.local.name], labels)}
            end)

        formatter.format_data(label, data, type, help)
      true ->
        :error
    end
  end

  @doc ~S"""
  Formats a keyword list of metrics using a given `formatter`.

  **Metrics**

  The key is the name of the metric and the value can be given in the following formats:
    - `data`
    - `{data, type}`
    - `{data, type, help}`

  The different fields are:
    - `data`, the actual metrics information.
    - `type`, the type of the metric.
              Possible values: `:gauge`, `:counter`.
    - `help`, a one line text description of the metric.

  The `data` can be given in the following formats:
    - `integer` | `float`, just a single value.
    - `map`, where every key will be turned into a type value.
    - `keyword` list, where every key will be turned into a type value
    - `list` of tuples with the following format: `{value, labels}`, where `labels` is a keyword list with labels and their values.
    - `function` | `string`, a function or String that can be evaluated to a function, which, when called, returns one of the above data-types.

  Example:
  ```elixir
  iex> Wobserver.Util.Metrics.Formatter.format_all [simple: 5]
  "simple{node=\"10.74.181.35\"} 5\n"
  ```

  ```elixir
  iex> Wobserver.Util.Metrics.Formatter.format_all [simple: {5, :gauge}]
  "# TYPE simple gauge\nsimple{node=\"10.74.181.35\"} 5\n"
  ```

  ```elixir
  iex> Wobserver.Util.Metrics.Formatter.format_all [simple: {5, :gauge, "Example desc."}]
  "# HELP simple Example desc.\n
  # TYPE simple gauge\n
  simple{node=\"10.74.181.35\"} 5\n"
  ```

  ```elixir
  iex> Wobserver.Util.Metrics.Formatter.format_all [simple: %{floor: 5, wall: 8}]
  "simple{node=\"10.74.181.35\",type=\"floor\"} 5\n
  simple{node=\"10.74.181.35\",type=\"wall\"} 8\n"
  ```

  ```elixir
  iex> Wobserver.Util.Metrics.Formatter.format_all [simple: [floor: 5, wall: 8]]
  "simple{node=\"10.74.181.35\",type=\"floor\"} 5\n
  simple{node=\"10.74.181.35\",type=\"wall\"} 8\n"
  ```

  ```elixir
  iex> Wobserver.Util.Metrics.Formatter.format_all [simple: [{5, [location: :floor]}, {8, [location: :wall]}]]
  "simple{node=\"10.74.181.35\",location=\"floor\"} 5\n
  simple{node=\"10.74.181.35\",location=\"wall\"} 8\n"
  ```
  """
  @spec format_all(data :: list, formatter :: atom) :: String.t | :error
  def format_all(data, formatter \\ nil)

  def format_all(data, nil) do
    format_all(data, Application.get_env(
      :wobserver,
      :metric_format,
      Wobserver.Util.Metrics.Prometheus
    ))
  end

  def format_all(data, formatter) do
    formatted =
      data
      |> Enum.map(&helper(&1, formatter))

    case Enum.member?(formatted, :error) do
      true -> :error
      _ -> formatted |> formatter.combine_metrics
    end
  end

  @doc ~S"""
  Merges formatted sets of metrics from different nodes together using a given `formatter`.

  The merge should prevent double declarations of help and type.

  Arguments:
    - `metrics`, a list of formatted sets metrics for multiple node.
  """
  @spec merge_metrics(metrics :: list(String.t), formatter :: atom)
   :: String.t | :error
  def merge_metrics(metrics, formatter \\ nil)

  def merge_metrics(metrics, nil) do
    merge_metrics(metrics,
      Application.get_env(
        :wobserver,
        :metric_format,
        Wobserver.Util.Metrics.Prometheus
      )
    )
  end

  def merge_metrics(metrics, formatter) do
    # Old way: One node error, means no metrics
    #
    # case Enum.member?(metrics, :error) do
    #   true -> :error
    #   false -> formatter.merge_metrics(metrics)
    # end
    metrics
    |> Enum.filter(fn m -> m != :error end)
    |> formatter.merge_metrics
  end

  # Helpers

  defp helper({key, {data, type, help}}, formatter) do
    format(data, Atom.to_string(key), type, help, formatter)
  end

  defp helper({key, {data, type}}, formatter) do
    format(data, Atom.to_string(key), type, nil, formatter)
  end

  defp helper({key, data}, formatter) do
    format(data, Atom.to_string(key), nil, nil, formatter)
  end

  defp map_to_data(map) do
    map
    |> Map.to_list
    |> Enum.filter(fn {a, _} -> a != :__struct__ && a != :total  end)
    |> list_to_data()
  end

  defp list_to_data(list) do
    list
    |> Enum.map(fn {key, value} -> {value, [type: key]} end)
  end
end

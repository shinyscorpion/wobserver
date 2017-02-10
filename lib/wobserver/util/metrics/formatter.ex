defmodule Wobserver.Util.Metrics.Formatter do
  @moduledoc ~S"""
  Formatter.

  TODO: Needs config.
  """

  alias Wobserver.Util.Node.Discovery

  @callback format_data(
    name :: String.t,
    data :: [{integer | float, keyword}],
    type :: :atom,
    help :: String.t
  ) :: String.t

  @callback combine_metrics(
    metrics :: list[String.t]
  ) :: String.t

  @callback merge_metrics(
    metrics :: list[String.t]
  ) :: String.t

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

  def format(data, label, type, help, formatter) do
    cond do
      is_map(data) ->
        data
        |> map_to_data()
        |> format(label, type, help, formatter)
      Keyword.keyword?(data) ->
        data
        |> list_to_data()
        |> format(label, type, help, formatter)
      is_binary(data) ->
        try do
          {new_data, []} = Code.eval_string data
          format(new_data, label, type, help, formatter)
        catch
          :error, _ -> :error
        end
      is_function(data) ->
        data.()
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

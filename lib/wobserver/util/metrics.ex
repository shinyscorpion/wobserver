defmodule Wobserver.Util.Metrics do
  @moduledoc ~S"""
  Metrics management for custom metrics and generators in wobserver.
  """

  alias Wobserver.System.Memory

  @metrics_table :wobserver_metrics

  @doc ~S"""
  Lists all metrics.

  Every generator is called and the generated metrics are merged into the result.
  """
  @spec overview :: keyword
  def overview do
    memory()
    |> Kernel.++(io())
    |> Keyword.merge(custom_metrics())
  end

  @doc ~S"""
  Memory metrics.

  See: `Wobserver.System.Memory.usage/0`.
  """
  @spec memory :: keyword
  def memory do
    [
      erlang_vm_used_memory_bytes: {
        &Memory.usage/0,
        :gauge,
        "Memory usage of the Erlang VM."
      }
    ]
  end

  @doc ~S"""
  IO metrics.
  """
  @spec io :: keyword
  def io do
    [
      erlang_vm_used_io_bytes: {
        "Tuple.to_list(:erlang.statistics(:io))",
        :counter,
        "IO counter for the Erlang VM."
      }
    ]
  end

  @doc ~S"""
  Registers a metrics or metric generators with `:wobserver`.

  The `metrics` parameter must always be a list of metrics or metric generators.

  Returns true if succesfully added. (otherwise false)

  The following inputs are accepted for metrics:
    - `keyword` list, the key is the name of the metric and the value is the metric data.

  The following inputs are accepted for metric generators:
    - `list` of callable functions.
      Every function should return a keyword list with as key the name of the metric and as value the metric data.

  For more information about how to format metric data see: `Wobserver.Util.Metrics.Formatter.format_all/1`.
  """
  @spec register(metrics :: list) :: boolean
  def register(metrics) when is_list(metrics) do
    ensure_storage()

    case Keyword.keyword?(metrics) do
      true ->
        @metrics_table
        |> Agent.update(fn %{generators: g, metrics: m} ->
          %{generators: g, metrics: Keyword.merge(m, metrics)}
        end)

      false ->
        @metrics_table
        |> Agent.update(fn %{generators: g, metrics: m} ->
          %{generators: g ++ metrics, metrics: m}
        end)
    end

    true
  end

  def register(_), do: false

  @doc ~S"""
  Loads custom metrics and metric generators from configuration and adds them to `:wobserver`.

  To add custom metrics set the `:metrics` option.
  The `:metrics` option must be a keyword list with the following keys:
    - `additional`, for a keyword list with additional metrics.
    - `generators`, for a list of metric generators.

  For more information and types see: `Wobserver.Util.Metrics.register/1`.

  Example:
  ```elixir
  config :wobserver,
    metrics: [
      additional: [
        example: {fn -> [red: 5] end, :gauge, "Description"},
      ],
      generators: [
        "&MyApp.generator/0",
        fn -> [bottles: {fn -> [wall: 8, floor: 10] end, :gauge, "Description"}] end
        fn -> [server: {"MyApp.Server.metrics/0", :gauge, "Description"}] end
      ]
    ]
  ```
  """
  @spec load_config :: true
  def load_config do
    ensure_storage()

    metrics =
      :wobserver
      |> Application.get_env(:metrics, [])
      |> Keyword.get(:additional, [])

    generators =
      :wobserver
      |> Application.get_env(:metrics, [])
      |> Keyword.get(:generators, [])

    @metrics_table
    |> Agent.update(fn %{generators: g, metrics: m} ->
      %{generators: g ++ generators, metrics: Keyword.merge(m, metrics)}
    end)

    true
  end

  # Helpers

  defp custom_metrics do
    ensure_storage()

    metrics =
      @metrics_table
      |> Agent.get(fn metrics -> metrics end)

    generators =
      metrics.generators
      |> Enum.reduce([], &generate/2)

    metrics.metrics
    |> Keyword.merge(generators)
  end

  defp generate(generator, results) when is_binary(generator) do
    {eval_generator, []} = Code.eval_string(generator)

    eval_generator
    |> generate(results)
  end

  defp generate(generator, results) do
    result = generator.()
    Keyword.merge(results, result)
  end

  defp ensure_storage do
    Agent.start_link(
      fn -> %{generators: [], metrics: []} end,
      name: @metrics_table
    )
  end
end

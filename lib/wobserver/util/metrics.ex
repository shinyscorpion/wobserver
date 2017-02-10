defmodule Wobserver.Util.Metrics do
  @moduledoc ~S"""
  Metrics

  TODO:
    - Needs config.
    - Needs docs.
    - Needs cleanup.
    - Needs tests.
  """

  alias Wobserver.System.Memory

  def overview do
    memory()
    |> Kernel.++(io())
    |> Keyword.merge(custom_metrics())
    |> Keyword.merge(custom_generated_metrics())
  end

  def memory do
    [erlang_vm_used_memory_bytes: {
      &Memory.usage/0,
      :gauge,
      "Memory usage of the Erlang VM."
    }]
  end

  def io do
    [erlang_vm_used_io_bytes: {
      "Tuple.to_list(:erlang.statistics(:io))",
      :counter,
      "IO counter for the Erlang VM."
    }]
  end

  defp custom_metrics do
    :wobserver
    |> Application.get_env(:metrics, [])
    |> Keyword.get(:additional, [])
  end

  defp custom_generated_metrics do
    :wobserver
    |> Application.get_env(:metrics, [])
    |> Keyword.get(:generators, [])
    |> Enum.reduce([], fn generator, m ->
         result = generator.()
         Keyword.merge(m, result)
       end)
  end
end

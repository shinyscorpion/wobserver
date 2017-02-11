defmodule Wobserver.Allocator do
  @moduledoc ~S"""
  Handles memory allocators and their block and carrier size.
  """

  @doc ~S"""
  Lists memory allocators and their block and carrier size.

  The returned maps contain the following information:
    - `type`, the type of the memory allocator.
    - `block`, the block size of the memory allocator. (summed over all schedulers)
    - `carrier`, the carrier size of the memory allocator. (summed over all schedulers)
  """
  @spec list :: list(map)
  def list do
    :alloc_util_allocators
    |> :erlang.system_info
    |> info()
  end

  defp info(type) do
    {:allocator_sizes, type}
    |> :erlang.system_info
    |> Enum.map(&sum_data/1)
    |> Enum.filter(&non_zero?/1)
  end

  defp non_zero?(%{carrier: c, block: b}), do: c != 0 && b != 0

  defp sum_data({type, data}) do
    data
    |> Enum.map(fn {_, _, d} -> Keyword.get(d,:mbcs) end)
    |> Enum.map(&block_and_carrier_size/1)
    |> Enum.reduce({0,0}, fn {x, y}, {a, b} -> {a + x, y + b} end)
    |> (fn {x, y} -> %{type: type, block: x, carrier: y} end).()
  end

  defp block_and_carrier_size([{_, x, _, _}, {_, y, _, _}]), do: {x, y}
end

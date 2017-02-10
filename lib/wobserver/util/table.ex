defmodule Wobserver.Table do
  @moduledoc ~S"""
  Table

  TODO:
    - Needs docs.
    - Needs cleanup.
    - Needs tests.
  """

  @spec list :: list(map)
  def list do
    :ets.all
    |> Enum.map(&info/1)
  end

  @spec info(table :: atom | integer, include_data :: boolean) :: map
  def info(table, include_data \\ false)

  def info(table, false) do
    %{
      id: table,
      name: :ets.info(table, :name),
      type: :ets.info(table, :type),
      size: :ets.info(table, :size),
      memory: :ets.info(table, :memory),
      owner: :ets.info(table, :owner),
      protection: :ets.info(table, :protection),
      meta: %{
        read_concurrency: :ets.info(table, :read_concurrency),
        write_concurrency: :ets.info(table, :write_concurrency),
        compressed: :ets.info(table, :compressed),
      },
    }
  end

  def info(table, true) do
    %{
      id: table,
      name: :ets.info(table, :name),
      type: :ets.info(table, :type),
      size: :ets.info(table, :size),
      memory: :ets.info(table, :memory),
      owner: :ets.info(table, :owner),
      protection: :ets.info(table, :protection),
      data: data(table),
      meta: %{
        read_concurrency: :ets.info(table, :read_concurrency),
        write_concurrency: :ets.info(table, :write_concurrency),
        compressed: :ets.info(table, :compressed),
      },
    }
  end

  @spec sanitize(table :: atom | integer | String.t) :: atom | integer
  def sanitize(table) when is_atom(table), do: table
  def sanitize(table) when is_integer(table), do: table
  def sanitize(table) when is_binary(table) do
    case Integer.parse(table) do
      {nr, ""} -> nr
      _ -> table |> Wobserver.Util.Process.string_to_module
    end
  end

  defp data(table) do
    case :ets.info(table, :protection) do
      :private ->
        []
      _ ->
        table
        |> :ets.match(:"$1")
        |> Enum.map(&data_row/1)
    end
  end

  defp data_row([row]) do
    row
    |> Tuple.to_list
    |> Enum.map(&(to_string(:io_lib.format("~tp", [&1]))))
  end
end

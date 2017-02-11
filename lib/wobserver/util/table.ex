defmodule Wobserver.Table do
  @moduledoc ~S"""
  Table (ets) information and listing.
  """

  import Wobserver.Util.Helper, only: [string_to_module: 1]

  @doc ~S"""
  Lists all tables with basic information.

  Note: data is not included.
  """
  @spec list :: list(map)
  def list do
    :ets.all
    |> Enum.map(&info/1)
  end

  @doc """
  Retreives table information.

  If `include_data` is set to `true`, it will also contain the table data.
  """
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
    table
    |> info(false)
    |> Map.put(:data, data(table))
  end

  @doc ~S"""
  Sanitizes a table name and returns either the table id or name.

  Example:
  ```bash
  iex> Wobserver.Table.sanitize :code
  :code
  ```
  ```bash
  iex> Wobserver.Table.sanitize 1
  1
  ```
  ```bash
  iex> Wobserver.Table.sanitize "code"
  :code
  ```
  ```bash
  iex> Wobserver.Table.sanitize "1"
  1
  ```
  """
  @spec sanitize(table :: atom | integer | String.t) :: atom | integer
  def sanitize(table) when is_atom(table), do: table
  def sanitize(table) when is_integer(table), do: table
  def sanitize(table) when is_binary(table) do
    case Integer.parse(table) do
      {nr, ""} -> nr
      _ -> table |> string_to_module()
    end
  end

  # Helpers

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

defmodule Wobserver.Port do
  @moduledoc ~S"""
  Port

  TODO:
    - Needs docs.
    - Needs cleanup.
    - Needs tests.
  """

  alias Poison.Encoder
  alias Encoder.BitString

  defimpl Encoder, for: Port do
    @spec encode(port :: port, options :: any) :: String.t
    def encode(port, options) do
      port
      |> inspect
      |> BitString.encode(options)
    end
  end

  @spec list :: list(map)
  def list do
    :erlang.ports
    |> Enum.map(&info/1)
  end

  defp info(port) do
    data =
      port
      |> :erlang.port_info

    %{
      id: Keyword.get(data, :id, -1),
      name: to_string(Keyword.get(data, :name, '')),
      links: Keyword.get(data, :links, []),
      connected: Keyword.get(data, :connected, nil),
      input: Keyword.get(data, :input, 0),
      output: Keyword.get(data, :output, 0),
      os_pid: Keyword.get(data, :os_pid, nil),
    }
  end
end

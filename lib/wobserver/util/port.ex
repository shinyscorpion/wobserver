defmodule Wobserver.Port do
  @moduledoc ~S"""
  Handles Ports and their information.
  """

  @doc ~S"""
  Lists ports and their block and carrier size.

  The returned maps contain the following information:
    - `id`
    - `port`
    - `name`
    - `links`
    - `connected`
    - `input`
    - `output`
    - `os_pid`
  """
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
      port: port,
      name: to_string(Keyword.get(data, :name, '')),
      links: Keyword.get(data, :links, []),
      connected: Keyword.get(data, :connected, nil),
      input: Keyword.get(data, :input, 0),
      output: Keyword.get(data, :output, 0),
      os_pid: Keyword.get(data, :os_pid, nil),
    }
  end
end

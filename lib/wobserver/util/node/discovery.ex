defmodule Wobserver.Util.Node.Discovery do
  @moduledoc ~S"""
  Helps discovering other nodes to connect to.

  The method used can be set in the config file by setting:
  ```elixir
  config :wobserver,
    discovery: :dns,
  ```

  The following methods can be used: (default: `:none`)

    - `:none`, just returns the local node.
    - `:dns`, use DNS to search for other nodes.
      The option `discovery_search` needs to be set to filter entries.
    - `:custom`, a function as String.

  # Example config

  No discovery: (is default)
  ```elixir
  config :wobserver,
    port: 80,
    discovery: :none
  ```

  Using dns as discovery service:
  ```elixir
  config :wobserver,
    port: 80,
    discovery: :dns,
    discovery_search: "google.nl"
  ```

  Using a custom function:
  ```elixir
  config :wobserver,
    port: 80,
    discovery: :custom,
    discovery_search: &MyApp.CustomDiscovery.discover/0
  ```

  Using a anonymous function:
  ```elixir
  config :wobserver,
    port: 80,
    discovery: :custom,
    discovery_search: fn -> [] end
  ```
  """

  alias Wobserver.Util.Node.Remote

  # Finding

  @doc ~S"""
  Searches for a node in the discovered nodes.

  The `search` will be used to filter through names, hosts and host:port combinations.

  The special values for search are:
    - `local`, will always return the local node.
  """
  @spec find(String.t()) ::
          :local
          | :unknown
          | {:remote, Remote.t()}
  def find("local"), do: :local

  def find(search) do
    found_node =
      Enum.find(discover(), fn %{name: name, host: host, port: port} ->
        search == name || search == host || search == "#{host}:#{port}"
      end)

    cond do
      found_node == nil -> :unknown
      local?(found_node) -> :local
      true -> {:remote, found_node}
    end
  end

  @doc ~S"""
  Retuns the local node.
  """
  def local do
    discover()
    |> Enum.find(fn %{local?: is_local} -> is_local end)
  end

  # Discoverying

  @doc ~S"""
  Discovers other nodes to connect to.

  The method used can be set in the config file by setting:
      config :wobserver,
        discovery: :dns,

  The following methods can be used: (default: `:none`)
    - `:none`, just returns the local node.
    - `:dns`, use DNS to search for other nodes.
      The option `discovery_search` needs to be set to filter entries.
    - `:custom`, a function as String.

  # Example config
  No discovery: (is default)
      config :wobserver,
        discovery: :none

  Using dns:
      config :wobserver,
        discovery: :dns,
        discovery_search: "google.nl"

  Using a custom function:
      config :wobserver,
        discovery: :custom,
        discovery_search: "&MyApp.CustomDiscovery.discover/0"
  """
  @spec discover :: list(Remote.t())
  def discover do
    nodes =
      :wobserver
      |> Application.get_env(:discovery, :none)
      |> discovery_call

    case Enum.find(nodes, fn %{local?: is_local} -> is_local end) do
      nil -> discovery_call(:none) ++ nodes
      _ -> nodes
    end
  end

  @spec discovery_call(:dns) :: list(Remote.t())
  defp discovery_call(:dns),
    do: dns_discover(Application.get_env(:wobserver, :discovery_search, nil))

  @spec discovery_call(:custom) :: list(Remote.t())
  defp discovery_call(:custom) do
    method = Application.get_env(:wobserver, :discovery_search, fn -> [] end)

    cond do
      is_binary(method) ->
        {call, []} = Code.eval_string(method)

        call.()

      is_function(method) ->
        method.()

      true ->
        []
    end
  end

  @spec discovery_call(:none) :: list(Remote.t())
  defp discovery_call(:none) do
    [
      %Remote{
        name: get_local_ip(),
        host: get_local_ip(),
        port: Wobserver.Application.port(),
        local?: true
      }
    ]
  end

  @spec dns_discover(search :: String.t()) :: list(Remote.t())
  defp dns_discover(search) when is_binary(search) do
    search
    |> String.to_charlist()
    |> :inet_res.lookup(:in, :a)
    |> Enum.map(&dns_to_node/1)
  end

  defp dns_discover(_), do: []

  # Helpers

  defp local?(%{name: "local"}), do: true

  defp local?(%{host: "127.0.0.1", port: port}),
    do: port == Wobserver.Application.port()

  defp local?(%{host: ip, port: port}),
    do: ip == get_local_ip() && port == Wobserver.Application.port()

  defp local?(_), do: false

  defp ip_to_string({ip1, ip2, ip3, ip4}), do: "#{ip1}.#{ip2}.#{ip3}.#{ip4}"

  defp dns_to_node(ip) do
    remote_ip = ip_to_string(ip)

    remote = %Remote{
      name: remote_ip,
      host: remote_ip,
      port: Wobserver.Application.port(),
      local?: false
    }

    %Remote{remote | local?: local?(remote)}
  end

  defp get_local_ip do
    # with  {:ok, ips} <- :inet.getif(),
    #       {ip, _, _} <- List.first(ips),
    #   do: ip_to_string(ip)
    {:ok, ips} = :inet.getif()
    {ip, _, _} = List.first(ips)
    ip_to_string(ip)
  end
end

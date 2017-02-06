defmodule Wobserver.NodeDiscoveryTest do
  use ExUnit.Case

  alias Wobserver.NodeDiscovery

  def custom_search do
    [
      %{
        name: "Remote 1",
        host: "192.168.1.34",
        port: 4001
      },
      %{
        name: "Remote 2",
        host: "84.23.12.175",
        port: 4001
      }
    ]
  end

  describe "find" do
    test "returns local for \"local\"" do
      assert NodeDiscovery.find("local") == :local
    end

    test "returns unknown for \"garbage\"" do
      assert NodeDiscovery.find("garbage") == :unknown
    end

    test "returns remote_note for \"Remote 1\"" do
      ip_address =
        with  {:ok, ips} <- :inet.getif(),
              {ip, _, _} <- List.first(ips),
              {ip1, ip2, ip3, ip4} <- ip,
          do: "#{ip1}.#{ip2}.#{ip3}.#{ip4}"

      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> fn -> [%{name: ip_address, host: ip_address, port: 0}] end
        end
      end

      on_exit(fn -> :meck.unload end)

      assert NodeDiscovery.find(ip_address) == :local
    end

    test "returns :local for machine ip" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> "&Wobserver.NodeDiscoveryTest.custom_search/0"
        end
      end

      on_exit(fn -> :meck.unload end)

      {:remote, node} = NodeDiscovery.find("Remote 1")

      assert node.host == "192.168.1.34"
    end
  end

  describe "discover" do
    test "returns local with no config" do
      [%{
        name: name,
        host: host,
        port: port,
      }] = NodeDiscovery.discover

      assert name == "local"
      assert is_binary(host)
      assert port > 0
    end

    test "returns local with config set to none" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, :discovery, :none) -> :none end

      on_exit(fn -> :meck.unload end)

      [%{
        name: name,
        host: host,
        port: port,
      }] = NodeDiscovery.discover

      assert name == "local"
      assert is_binary(host)
      assert port > 0
    end

    test "returns local with config set to dns and localhost." do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :dns
          :discovery_search -> "localhost."
        end
      end

      on_exit(fn -> :meck.unload end)

      [%{
        name: name,
        host: host,
        port: port,
      }] = NodeDiscovery.discover

      assert name == host
      assert name == "127.0.0.1"
      assert port > 0
    end

    test "returns info with config set to dns and non local host" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :dns
          :discovery_search -> "google.nl."
        end
      end

      on_exit(fn -> :meck.unload end)

      [%{
        name: name,
        host: host,
        port: port,
      }] = NodeDiscovery.discover

      assert name == host
      assert is_binary(name)
      assert port > 0
    end

    test "returns nodes with config set to custom function as String" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> "&Wobserver.NodeDiscoveryTest.custom_search/0"
        end
      end

      on_exit(fn -> :meck.unload end)

      [
        %{
          name: name,
        },
        %{
          name: _name,
          host: _host,
          port: _port,
        },
      ] = NodeDiscovery.discover

      assert name == "Remote 1"
    end

    test "returns nodes with config set to custom function" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> &Wobserver.NodeDiscoveryTest.custom_search/0
        end
      end

      on_exit(fn -> :meck.unload end)

      [
        %{
          name: name,
        },
        %{
        },
      ] = NodeDiscovery.discover

      assert name == "Remote 1"
    end

    test "returns nodes with config set to lambda function as String" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> "fn -> [%{name: \"Remote 1\", host: nil, port: 0}] end"
        end
      end

      on_exit(fn -> :meck.unload end)

      [
        %{
          name: name,
        }
      ] = NodeDiscovery.discover

      assert name == "Remote 1"
    end

    test "returns nodes with config set to lambda function" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> fn -> [%{name: "Remote 1", host: nil, port: 0}] end
        end
      end

      on_exit(fn -> :meck.unload end)

      [
        %{
          name: name,
        }
      ] = NodeDiscovery.discover

      assert name == "Remote 1"
    end
  end
end

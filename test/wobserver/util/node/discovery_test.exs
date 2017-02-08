defmodule Wobserver.Util.Node.DiscoveryTest do
  use ExUnit.Case

  alias Wobserver.Util.Node.Remote
  alias Wobserver.Util.Node.Discovery

  def custom_search do
    [
      %Remote{
        name: "Remote 1",
        host: "192.168.1.34",
        port: 4001
      },
      %Remote{
        name: "Remote 2",
        host: "84.23.12.175",
        port: 4001
      }
    ]
  end

  describe "find" do
    test "returns local for \"local\"" do
      assert Discovery.find("local") == :local
    end

    test "returns unknown for \"garbage\"" do
      assert Discovery.find("garbage") == :unknown
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
          :discovery_search -> fn -> [%Remote{name: ip_address, host: ip_address, port: 0}] end
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      assert Discovery.find(ip_address) == :local
    end

    test "returns :local for machine ip" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> "&Wobserver.Util.Node.DiscoveryTest.custom_search/0"
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      {:remote, node} = Discovery.find("Remote 1")

      assert node.host == "192.168.1.34"
    end

    test "returns :local for 127.0.0.1 and matching port" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> fn -> [%Remote{name: "Remote 1", host: "127.0.0.1", port: 4001}] end
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      assert Discovery.find("Remote 1") == :local
    end
  end

  describe "discover" do
    test "returns local with no config" do
      [%{
        name: name,
        host: host,
        port: port,
      }] = Discovery.discover

      assert is_binary(name)
      assert is_binary(host)
      assert port > 0
    end

    test "returns local with config set to none" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :none
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      [%{
        name: name,
        host: host,
        port: port,
      }] = Discovery.discover

      assert is_binary(name)
      assert is_binary(host)
      assert port > 0
    end

    test "returns local with config set to dns and localhost." do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :dns
          :discovery_search -> "localhost."
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      [%{
        name: name,
        host: host,
        port: port,
      }] = Discovery.discover

      assert name == host
      assert is_binary(host)
      assert port > 0
    end

    test "returns info with config set to dns and non local host" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :dns
          :discovery_search -> "disovery.services.local."
          :port -> 4001
        end
      end

      :meck.new :inet_res, [:unstick]
      :meck.expect :inet_res, :lookup, fn (_, _, _) ->
        {:ok, ips} = :inet.getif()
        {ip, _, _} = List.first(ips)
        [ip]
      end

      on_exit(fn -> :meck.unload end)

      [%{
        name: name,
        host: host,
        port: port,
      }] = Discovery.discover

      assert is_binary(name)
      assert is_binary(host)
      assert port > 0
    end

    test "returns nodes with config set to custom function as String" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> "&Wobserver.Util.Node.DiscoveryTest.custom_search/0"
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      [_, remote, _] = Discovery.discover

      assert remote.name == "Remote 1"
    end

    test "returns nodes with config set to custom function" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> &Wobserver.Util.Node.DiscoveryTest.custom_search/0
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      [_, remote, _] = Discovery.discover

      assert remote.name == "Remote 1"
    end

    test "returns nodes with config set to lambda function as String" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> "fn -> [%Wobserver.Util.Node.Remote{name: \"Remote 1\", host: nil, port: 0}] end"
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      [_, remote] = Discovery.discover

      assert remote.name == "Remote 1"
    end

    test "returns nodes with config set to lambda function" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> fn -> [%Remote{name: "Remote 1", host: nil, port: 0}] end
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      [_, remote] = Discovery.discover

      assert remote.name == "Remote 1"
    end
  end
end

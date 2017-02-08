defmodule Wobserver.Util.Node.RemoteTest do
  use ExUnit.Case, async: false

  alias Wobserver.Util.Node.Remote
  alias Wobserver.Web.ClientProxy

  describe "metrics" do
    test "does remote calls" do
      :meck.new HTTPoison, [:passthrough]
      :meck.expect HTTPoison, :get, fn _ -> {:ok, %{body: "ok"}} end

      on_exit(fn -> :meck.unload end)

      assert Remote.metrics(%{host: "", port: 80, local?: false}) == "ok"
    end
  end

  describe "socket_proxy" do
    test ":local returns {nil, local}" do
      assert Remote.socket_proxy(:local) == {nil, "local"}
    end

    test "local node returns {nil, local}" do
      assert Remote.socket_proxy(%{local?: true}) == {nil, "local"}
    end

    test "remote local node returns {nil, local}" do
      assert Remote.socket_proxy({:remote, %{local?: true}}) == {nil, "local"}
    end

    test "invalid argument returns error" do
      assert {:error, _} = Remote.socket_proxy(:invalid)
    end

    test "remote opens connection (on ok)" do
      :meck.new ClientProxy, [:passthrough]
      :meck.expect ClientProxy, :connect, fn _ -> {:ok, 5} end

      on_exit(fn -> :meck.unload end)

      assert Remote.socket_proxy(%{host: "", port: 1, name: "a", local?: false}) == {5, "a"}
    end

    test "remote opens connection (on error)" do
      :meck.new ClientProxy, [:passthrough]
      :meck.expect ClientProxy, :connect, fn _ -> :invalid end

      on_exit(fn -> :meck.unload end)

      assert {:error, _} = Remote.socket_proxy(%{host: "", port: 1, name: ""})
    end
  end
end

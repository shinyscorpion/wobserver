defmodule Wobserver.Web.Router.ApiTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Wobserver.Util.Node.Remote
  alias Wobserver.Web.Router.Api

  @opts Api.init([])

  test "/about returns about" do
    conn = conn(:get, "/about")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.encode!(Wobserver.about) == conn.resp_body
  end

  test "/nodes returns nodes" do
    conn = conn(:get, "/nodes")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.encode!(Wobserver.Util.Node.Discovery.discover) == conn.resp_body
  end

  test "/system returns 200" do
    conn = conn(:get, "/system")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/local/system returns 200" do
    conn = conn(:get, "/local/system")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/blurb/system returns 404" do
    conn = conn(:get, "/blurb/system")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end

  test "/remote/system returns 500 (can't load)" do
    :meck.new Application, [:passthrough]
    :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
      case field do
        :port -> 4001
        :discovery -> :custom
        :discovery_search -> fn -> [%Wobserver.Util.Node.Remote{name: "remote", host: "85.65.12.4", port: 0}] end
      end
    end

    on_exit(fn -> :meck.unload end)

    conn = conn(:get, "/remote/system")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 500
  end

  test "/remote/system returns 200" do
    :meck.new Application, [:passthrough]
    :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
      case field do
        :port -> 4001
        :discovery -> :custom
        :discovery_search -> fn -> [%Wobserver.Util.Node.Remote{name: "remote", host: "85.65.12.4", port: 0}] end
      end
    end

    :meck.new Remote, [:passthrough]
    :meck.expect Remote, :api, fn _, _ -> "data" end

    on_exit(fn -> :meck.unload end)

    conn = conn(:get, "/remote/system")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "unknown url returns 501 for custom commands" do
    conn = conn(:get, "/unknown")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 501
  end

  test "unknown url returns 404 for index" do
    conn = conn(:get, "/")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

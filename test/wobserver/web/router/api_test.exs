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

  test "/application returns 200" do
    conn = conn(:get, "/application")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/application/:app returns 200" do
    conn = conn(:get, "/application/wobserver")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/process returns 200" do
    conn = conn(:get, "/process")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/process/:process returns 200" do
    conn = conn(:get, "/process/Logger")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/table returns 200" do
    conn = conn(:get, "/table")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/table/:table returns 200" do
    conn = conn(:get, "/table/1")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/ports returns 200" do
    conn = conn(:get, "/ports")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/allocators returns 200" do
    conn = conn(:get, "/allocators")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
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
        :metric_format -> Wobserver.Util.Metrics.Prometheus
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
        :metric_format -> Wobserver.Util.Metrics.Prometheus
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

  test "custom url returns 200 for custom list" do
    conn = conn(:get, "/custom")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "unknown url returns 200 for known custom commands" do
    Wobserver.register(:page, {"Test", :test, fn -> 5 end})

    conn = conn(:get, "/test")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "unknown url returns 404 for unknown custom commands" do
    conn = conn(:get, "/unknown")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end

  test "unknown url returns 404 for index" do
    conn = conn(:get, "/")

    conn = Api.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

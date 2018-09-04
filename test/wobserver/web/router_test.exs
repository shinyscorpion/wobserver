defmodule Wobserver.Web.RouterTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Wobserver.Web.Router

  @opts Router.init([])

  test "/api/nodes returns nodes" do
    conn = conn(:get, "/api/nodes")

    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.encode!(Wobserver.Util.Node.Discovery.discover()) == conn.resp_body
  end

  test "/ returns 200" do
    conn = conn(:get, "/")

    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/metrics returns 200" do
    conn = conn(:get, "/metrics")

    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "unknown url returns 404" do
    conn = conn(:get, "/unknown")

    conn = Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

defmodule Wobserver.Web.Router.StaticTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Wobserver.Web.Router.Static

  @opts Static.init([])

  test "/ returns 200" do
    conn = conn(:get, "/")

    conn = Static.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/main.css returns 200" do
    conn = conn(:get, "/main.css")

    conn = Static.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/app.js returns 200" do
    conn = conn(:get, "/app.js")

    conn = Static.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/license returns 200" do
    conn = conn(:get, "/license")

    conn = Static.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "unknown url returns 404" do
    conn = conn(:get, "/unknown")

    conn = Static.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

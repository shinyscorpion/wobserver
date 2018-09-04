defmodule Wobserver.Web.Router.SystemTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Wobserver.Web.Router.System

  @opts System.init([])

  test "/ returns overview" do
    conn = conn(:get, "/")

    conn = System.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert %{
             "architecture" => _,
             "cpu" => _,
             "memory" => _,
             "statistics" => _
           } = Poison.decode!(conn.resp_body)
  end

  test "/architecture returns architecture" do
    conn = conn(:get, "/architecture")

    conn = System.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.encode!(Wobserver.System.Info.architecture()) == conn.resp_body
  end

  test "/cpu returns cpu" do
    conn = conn(:get, "/cpu")

    conn = System.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
    assert Poison.encode!(Wobserver.System.Info.cpu()) == conn.resp_body
  end

  test "/memory returns memory" do
    conn = conn(:get, "/memory")

    conn = System.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert %{
             "atom" => _,
             "binary" => _,
             "code" => _,
             "ets" => _,
             "process" => _,
             "total" => _
           } = Poison.decode!(conn.resp_body)
  end

  test "/statistics returns statistics" do
    conn = conn(:get, "/statistics")

    conn = System.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    assert %{
             "uptime" => _,
             "process_running" => _,
             "process_total" => _,
             "process_max" => _,
             "input" => _,
             "output" => _
           } = Poison.decode!(conn.resp_body)
  end

  test "unknown url returns 404" do
    conn = conn(:get, "/unknown")

    conn = System.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

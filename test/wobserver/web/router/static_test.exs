defmodule Wobserver.Web.Router.StaticTest do
  use ExUnit.Case, async: false
  use Plug.Test

  alias Wobserver.Web.Router.Static

  @opts Static.init([])

  describe "with config set to false" do
    setup do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :assets -> false
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      :ok
    end

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
  end

  describe "with config set to \"\"" do
    setup do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :assets -> ""
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      :ok
    end

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
  end

  test "unknown url returns 404" do
    conn = conn(:get, "/unknown")

    conn = Static.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

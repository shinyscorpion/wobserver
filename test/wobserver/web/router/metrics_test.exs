defmodule Wobserver.Web.Router.MetricsTest do
  use ExUnit.Case, async: false
  use Plug.Test

  alias Wobserver.Util.Metrics.Formatter
  alias Wobserver.Util.Node.Remote
  alias Wobserver.Web.Router.Metrics

  @opts Metrics.init([])

  def test_generator do
    [
      task_bunny_queue: {
        [normal: 5],
        :gauge,
        "The amount of task bunny queues used"
      }
    ]
  end

  describe "/" do
    test "returns 200" do
      conn = conn(:get, "/")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
    end

    test "returns 500 with failed format" do
      :meck.new Formatter, [:passthrough]
      :meck.expect Formatter, :format_all, fn _ -> :error end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/memory")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 500
    end

    test "returns 200 with custom metrics" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :metrics ->
            [additional: [
              task_bunny_queue: {
                [normal: 5],
                :gauge,
                "The amount of task bunny queues used"
              }
            ]]
          :metric_format -> Wobserver.Util.Metrics.Prometheus
          :discovery -> :none
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
    end

    test "returns 200 with custom generator" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :metrics ->
            [generators: [&Wobserver.Web.Router.MetricsTest.test_generator/0]]
          :metric_format -> Wobserver.Util.Metrics.Prometheus
          :discovery -> :none
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
    end

    test "returns 200 with invalid custom metrics" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :metrics ->
            [additional: [
              task_bunny_queue: {
                5,
                :gauge,
                "The amount of task bunny queues used"
              }
            ]]
          :metric_format -> Wobserver.Util.Metrics.Prometheus
          :discovery -> :none
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
    end

    test "returns 500 if metrics can not be generated" do
      :meck.new Formatter, [:passthrough]
      :meck.expect Formatter, :merge_metrics, fn (_) -> :error end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 500
    end
  end

  describe "remote nodes" do
    test "/n/local" do
      conn = conn(:get, "/n/local")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
    end

    test "/n/unknown" do
      conn = conn(:get, "/n/unknown")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 404
    end

    test "/n/remote without error" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> fn -> [%Remote{name: "remote", host: "127.0.0.5", port: 4001}] end
          :port -> 4001
        end
      end

      :meck.new Remote, [:passthrough]
      :meck.expect Remote, :metrics, fn _ -> "ok" end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/n/remote")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 200
    end

    test "/n/remote with error" do
      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, field, _) ->
        case field do
          :discovery -> :custom
          :discovery_search -> fn -> [%Remote{name: "remote", host: "127.0.0.5", port: 4001}] end
          :port -> 4001
        end
      end

      :meck.new Remote, [:passthrough]
      :meck.expect Remote, :metrics, fn _ -> :error end

      on_exit(fn -> :meck.unload end)

      conn = conn(:get, "/n/remote")

      conn = Metrics.call(conn, @opts)

      assert conn.state == :sent
      assert conn.status == 500
    end
  end

  test "/memory" do
    conn = conn(:get, "/memory")

    conn = Metrics.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end

  test "/io" do
    conn = conn(:get, "/io")

    conn = Metrics.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200
  end


  test "unknown url returns 404" do
    conn = conn(:get, "/unknown")

    conn = Metrics.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 404
  end
end

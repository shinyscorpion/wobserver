defmodule Wobserver.Web.Router.HelperTest do
  use ExUnit.Case, async: true
  use Plug.Test

  alias Wobserver.Web.Router.Helper

  test "returns 200 with atom" do
    conn = conn(:get, "/")

    conn = Helper.send_json_resp(:info, conn)

    assert conn.status == 200
  end

  test "returns 200 with String" do
    conn = conn(:get, "/")

    conn = Helper.send_json_resp("info", conn)

    assert conn.status == 200
  end

  test "returns 200 with map" do
    conn = conn(:get, "/")

    conn = Helper.send_json_resp(%{data: "info"}, conn)

    assert conn.status == 200
  end

  test "returns 200 with list" do
    conn = conn(:get, "/")

    conn = Helper.send_json_resp(["info", "list"], conn)

    assert conn.status == 200
  end

  test "returns 500 with invalid data" do
    conn = conn(:get, "/")

    conn = Helper.send_json_resp({:invalid}, conn)

    assert conn.status == 500
  end
end

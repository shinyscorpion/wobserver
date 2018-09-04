defmodule Wobserver.PortTest do
  use ExUnit.Case

  alias Wobserver.Port

  describe "list" do
    test "returns a list" do
      assert is_list(Port.list())
    end

    test "returns a list of maps" do
      assert is_map(List.first(Port.list()))
    end

    test "returns a list of table information" do
      assert %{
               id: _,
               port: _,
               name: _,
               links: _,
               connected: _,
               input: _,
               output: _,
               os_pid: _
             } = List.first(Port.list())
    end
  end
end

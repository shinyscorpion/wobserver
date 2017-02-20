defmodule Wobserver.Util.ApplicationTest do
  use ExUnit.Case

  alias Wobserver.Util.Application

  describe "list" do
    test "returns a list" do
      assert is_list(Application.list)
    end

    test "returns a list of map" do
      assert is_map(List.first(Application.list))
    end

    test "returns a list of process summary information" do
      assert %{
        name: _,
        description: _,
        version: _
      } = List.first(Application.list)
    end
  end

  describe "info" do
    test "returns a structure with application information" do
      assert %{
        pid: pid,
        name: name,
        meta: %{
          class: :application
        },
        children: children,
      } = Application.info(:wobserver)

      assert is_pid(pid)
      assert is_binary(name)
      assert is_list(children)
    end
  end
end

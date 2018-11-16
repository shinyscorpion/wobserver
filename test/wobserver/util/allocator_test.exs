defmodule Wobserver.AllocatorTest do
  use ExUnit.Case

  alias Wobserver.Allocator

  describe "list" do
    test "returns a list" do
      assert is_list(Allocator.list())
    end

    test "returns a list of maps" do
      assert is_map(List.first(Allocator.list()))
    end

    test "returns a list of table information" do
      assert %{
               type: _,
               block: _,
               carrier: _
             } = List.first(Allocator.list())
    end
  end
end

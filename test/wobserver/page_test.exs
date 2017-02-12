defmodule Wobserver.PageTest do
  use ExUnit.Case

  alias Wobserver.Page

  describe "list" do
    test "returns a list" do
      assert is_list(Page.list)
    end

    test "returns a list of maps" do
      assert is_map(List.first(Page.list))
    end

    test "returns a list of table information" do
      assert %{
        title: _,
        command: _,
        api_only: _,
        refresh: _,
      } = List.first(Page.list)
    end
  end

  describe "find" do
    test "returns :page_not_found for unknown page" do
      assert Page.find(:does_not_exist) == :page_not_found
    end

    test "returns data from a call based on registered page" do
      Page.register("Test", :test, fn -> 5 end)

      assert %Page{
        title: "Test",
        command: :test,
        callback: _,
        options: %{api_only: false, refresh: 1.0}
      } = Page.find(:test)
    end
  end

  describe "call" do
    test "returns :page_not_found for :page_not_found" do
      assert Page.call(:page_not_found) == :page_not_found
    end

    test "returns :page_not_found for unknown page" do
      assert Page.call(:does_not_exist) == :page_not_found
    end

    test "returns data from a call based on structure" do
      assert Page.call(%Page{title: "", command: :command, callback: fn -> 5 end}) == 5
    end

    test "returns data from a call based on registered page" do
      Page.register("Test", :test, fn -> 5 end)

      assert Page.call(:test) == 5
    end
  end

  describe "register" do
    test "can register page" do
      Page.register "Test", :test, fn -> 5 end

      assert %Page{
        title: "Test",
        command: :test,
        callback: _,
        options: %{api_only: false, refresh: 1.0}
      } = Page.find(:test)
    end

    test "can register page with options" do
      Page.register "Test", :test, fn -> 5 end, api_only: true

      assert %Page{
        title: "Test",
        command: :test,
        callback: _,
        options: %{api_only: true, refresh: 1.0}
      } = Page.find(:test)
    end

    test "can register page with tuple" do
      Page.register {"Test", :test, fn -> 5 end}

      assert %Page{
        title: "Test",
        command: :test,
        callback: _,
        options: %{api_only: false, refresh: 1.0}
      } = Page.find(:test)
    end

    test "can register page with tuple and options" do
      Page.register {"Test", :test, fn -> 5 end, [api_only: true]}

      assert %Page{
        title: "Test",
        command: :test,
        callback: _,
        options: %{api_only: true, refresh: 1.0}
      } = Page.find(:test)
    end

    test "can register page with struct" do
      fun = fn -> 5 end

      Page.register %{
        title: "Test",
        command: :test,
        callback: fun
      }

      assert %Page{
        title: "Test",
        command: :test,
        callback: ^fun,
        options: %{api_only: false, refresh: 1.0}
      } = Page.find(:test)
    end

    test "can register page with struct and options" do
      fun = fn -> 5 end

      Page.register %{
        title: "Test",
        command: :test,
        callback: fun,
        options: [api_only: true]
      }

      assert %Page{
        title: "Test",
        command: :test,
        callback: ^fun,
        options: %{api_only: true, refresh: 1.0}
      } = Page.find(:test)
    end

    test "can register page with page" do
      fun = fn -> 5 end

      Page.register %Page{
        title: "Test",
        command: :test,
        callback: fun,
        options: %{api_only: true, refresh: 1.0}
      }

      assert %Page{
        title: "Test",
        command: :test,
        callback: ^fun,
        options: %{api_only: true, refresh: 1.0}
      } = Page.find(:test)
    end
  end

  describe "load_config" do
    test "loads from config" do
      fun = fn -> 5 end

      :meck.new Application, [:passthrough]
      :meck.expect Application, :get_env, fn (:wobserver, option, _) ->
        case option do
          :pages -> [{"Test", :test, fun, [api_only: true]}]
          :discovery -> :none
          :port -> 4001
        end
      end

      on_exit(fn -> :meck.unload end)

      Page.load_config

      assert %Page{
        title: "Test",
        command: :test,
        callback: ^fun,
        options: %{api_only: true, refresh: 1.0}
      } = Page.find(:test)
    end
  end
end

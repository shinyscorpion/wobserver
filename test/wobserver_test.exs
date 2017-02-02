defmodule WobserverTest do
  use ExUnit.Case

  describe "about" do
    test "includes name" do
      assert %{name: "Wobserver"} = Wobserver.about
    end

    test "includes version" do
      version =
        case :application.get_key(:wobserver, :vsn) do
          {:ok, v} -> List.to_string v
          _ -> "Unknown"
        end

      assert %{version: ^version} = Wobserver.about
    end

    test "includes description" do
      assert %{description: "Web based metrics, monitoring, and observer."} = Wobserver.about
    end

    test "includes license" do
      %{license: license} = Wobserver.about
      assert license.name == "MIT"
    end

    test "includes links" do
      %{links: links} = Wobserver.about

      assert Enum.count(links) > 0
    end
  end
end

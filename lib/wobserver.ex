defmodule Wobserver do
  @moduledoc """
  Web based metrics, monitoring, and observer.
  """

  @doc ~S"""
  Information about Wobserver.

  Returns a map containing:
    - `name`, name of `:wobserver`.
    - `version`, used `:wobserver` version.
    - `description`, description of `:wobserver`.
    - `license`, `:wobserver` license name and link.
    - `links`, list of name + url for `:wobserver` related information.
  """
  @spec about :: map
  def about do
    version =
      case :application.get_key(:wobserver, :vsn) do
        {:ok, v} -> List.to_string v
        _ -> "Unknown"
      end

    %{
      name: "Wobserver",
      version: version,
      description: "Web based metrics, monitoring, and observer.",
      license: %{
          name: "MIT",
          url: "license",
      },
      links: [
        %{
          name: "Hex",
          url: "https://hex.pm/packages/wobserver",
        },
        %{
          name: "Docs",
          url: "https://hexdocs.pm/wobserver/",
        },
        %{
          name: "Github",
          url: "https://github.com/shinyscorpion/wobserver",
        },
      ],
    }
  end
end

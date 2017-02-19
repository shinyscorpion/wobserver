defmodule Wobserver do
  @moduledoc """
  Web based metrics, monitoring, and observer.
  """

  alias Wobserver.Page
  alias Wobserver.Util.Metrics

  @doc ~S"""
  Registers external application to integrate with `:wobserver`.

  The registration is done by passing a `type` and the `data` to register.
  The `data` is usually passed on to a specialized function.

  The following types can be registered:
    - `:page`, see: `Wobserver.Page.register/1`.
    - `:metric`, see: `Wobserver.Util.Metrics.register/1`.
  """
  @spec register(type :: atom, data :: any) :: boolean
  def register(type, data)

  def register(:page, page), do: Page.register(page)
  def register(:metric, metric), do: Metrics.register(metric)

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

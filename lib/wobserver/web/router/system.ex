defmodule Wobserver.Web.Router.System do
  @moduledoc ~S"""
  System router.

  Returns the following resources:
    - `/` => `Wobserver.System.overview/0`.
    - `/architecture` => `Wobserver.System.Info.architecture/0`.
    - `/cpu` => `Wobserver.System.Info.cpu/0`.
    - `/memory` => `Wobserver.System.Memory.usage/0`.
    - `/statistics` => `Wobserver.System.Statistics.overview/0`.
  """

  use Wobserver.Web.Router.Base

  alias Wobserver.System
  alias System.{
    Info,
    Memory,
    Statistics,
  }

  get "/" do
    System.overview
    |> send_json_resp(conn)
  end

  get "/architecture" do
    Info.architecture
    |> send_json_resp(conn)
  end

  get "/cpu" do
    Info.cpu
    |> send_json_resp(conn)
  end

  get "/memory" do
    Memory.usage
    |> send_json_resp(conn)
  end

  get "/statistics" do
    Statistics.overview
    |> send_json_resp(conn)
  end

  match _ do
    conn
    |> send_resp(404, "Pages not Found")
  end
end

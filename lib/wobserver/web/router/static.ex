defmodule Wobserver.Web.Router.Static do
  @moduledoc ~S"""
  Static router mostly for the browsers interface.

  Returns the following resources:
    - `/`, for the main html page.
    - `/main.css`, for main css stylesheet.
    - `/app.js`, for the Javascript code.
    - `/license`, for the *MIT* license information.
  """

  use Plug.Router

  plug :match
  plug :dispatch

  @root_directory Application.get_env(:wobserver, :assets, "deps/wobserver/")

  get "/" do
    conn
    |> put_resp_content_type("text/html")
    |> send_file(200, "#{@root_directory}assets/index.html");
  end

  get "/main.css" do
    conn
    |> put_resp_content_type("text/css")
    |> send_file(200, "#{@root_directory}assets/main.css");
  end

  get "/app.js" do
    conn
    |> put_resp_content_type("application/javascript")
    |> send_file(200, "#{@root_directory}assets/app.js");
  end

  get "/license" do
    conn
    |> send_file(200, "#{@root_directory}LICENSE");
  end

  match _ do
    conn
    |> send_resp(404, "Page not Found")
  end
end

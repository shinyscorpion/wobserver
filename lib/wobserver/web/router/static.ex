defmodule Wobserver.Web.Router.Static do
  @moduledoc ~S"""
  Static router mostly for the browsers interface.

  Returns the following resources:
    - `/`, for the main html page.
    - `/main.css`, for main css stylesheet.
    - `/app.js`, for the Javascript code.
    - `/license`, for the *MIT* license information.
  """

  use Wobserver.Web.Router.Base

  alias Wobserver.Assets

  @security Application.get_env(:wobserver, :security, Wobserver.Security)

  get "/" do
    conn = @security.authenticate(conn)

    case String.ends_with?(conn.request_path, "/") do
      true ->
        conn
        |> put_resp_content_type("text/html")
        |> send_asset("assets/index.html", &Assets.html/0)
      false ->
        conn
        |> put_resp_header("location", conn.request_path <> "/")
        |> resp(301, "Redirecting to Wobserver.")
    end
  end

  get "/main.css" do
    conn
    |> put_resp_content_type("text/css")
    |> send_asset("assets/main.css", &Assets.css/0)
  end

  get "/app.js" do
    conn
    |> put_resp_content_type("application/javascript")
    |> send_asset("assets/app.js", &Assets.js/0)
  end

  get "/license" do
    conn
    |> send_asset("LICENSE", &Assets.license/0)
  end

  match _ do
    conn
    |> send_resp(404, "Page not Found")
  end

  # Helpers

  case Application.get_env(:wobserver, :assets, false) do
    false ->
      defp send_asset(conn, _asset, fallback) do
        conn
        |> send_resp(200, fallback.())
      end
    root ->
      defp send_asset(conn, asset, fallback) do
        case File.exists?(unquote(root) <> asset) do
          true ->
            conn
            |> send_file(200, unquote(root) <> asset)
          false ->
            conn
            |> send_resp(200, fallback.())
        end
      end
  end
end

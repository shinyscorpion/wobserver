defmodule Wobserver.Security do
  @moduledoc false

  alias Plug.Conn

  @secret "security-secret"

  @spec authenticate(Conn.t) :: Conn.t
  def authenticate(conn) do
    Conn.put_resp_cookie(
      conn,
      "_wobserver",
      generate(conn.remote_ip, conn.req_headers)
    )
  end

  @spec authenticated?(Conn.t) :: boolean
  def authenticated?(conn = %Conn{}) do
    conn = Conn.fetch_cookies(conn)

    case conn.cookies["_wobserver"] do
      nil -> false
      key -> key == generate(conn.remote_ip, conn.req_headers)
    end
  end

  @spec authenticated?(:cowboy_req.req) :: boolean
  def authenticated?(req) do
    {ip, _} = elem(req, 7)
    headers = elem(req, 16)

    cookies =
      Enum.find_value(headers, "", fn
          {"cookie", value} -> value
          _ -> false
      end)

    String.contains? cookies, ("_wobserver=" <> generate(ip, headers))
  end

  @spec generate(tuple, list(tuple)) :: String.t
  defp generate(remote_ip, headers) do
    ip =
      remote_ip
      |> Tuple.to_list
      |> Enum.map(&to_string/1)
      |> Enum.join(".")

    user_agent =
      Enum.find_value(headers, "unknown", fn
          {"user-agent", value} -> value
          _ -> false
      end)

    @secret
    |> hmac(ip)
    |> hmac(user_agent)
    |> Base.encode16
    |> String.downcase
  end

  @spec hmac(String.t | list(String.t), String.t) :: String.t
  defp hmac(encryption_key, data),
    do: :crypto.hmac(:sha256, encryption_key, data)
end

defmodule Wobserver.Security do
  @moduledoc ~S"""
  Handles basic websocket authentication.

  A different module with the following methods can be set as `:security` in the config:

   - `authenticate(Conn.t) :: Conn.t`
   - `authenticated?(Conn.t) :: boolean`
   - `authenticated?(:cowboy_req.req) :: boolean`
  """

  alias Plug.Conn

  @secret Application.get_env(:wobserver, :security_key, "secret-key-setting")
  @verify_remote_ip Application.get_env(:wobserver, :verify_remote_ip, false)

  @doc ~S"""
  Authenticates a given `conn`.
  """
  @spec authenticate(Conn.t) :: Conn.t
  def authenticate(conn) do
    Conn.put_resp_cookie(
      conn,
      "_wobserver",
      generate(conn.remote_ip, conn.req_headers)
    )
  end

  @doc ~S"""
  Checks whether a given `conn` is authenticated.
  """
  @spec authenticated?(Conn.t) :: boolean
  def authenticated?(conn = %Conn{}) do
    conn = Conn.fetch_cookies(conn)

    case conn.cookies["_wobserver"] do
      nil -> false
      key -> key == generate(conn.remote_ip, conn.req_headers)
    end
  end

  @doc ~S"""
  Checks whether a given `req` is authenticated.
  """
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
    ip = if @verify_remote_ip do
      remote_ip
      |> Tuple.to_list
      |> Enum.map(&to_string/1)
      |> Enum.join(".")
    else
      ""
    end

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

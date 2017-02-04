defmodule Wobserver.Web.Client do
  @moduledoc ~S"""
  Modules handles WebSocket connects to the client.
  """
  use Wobserver.Web.ClientSocket

  alias Wobserver.System

  def client_init do
    {:ok, %{}}
  end

  @spec client_handle(:hello, state :: map) :: {:reply, :ehlo, map}
  def client_handle(:hello, state) do
    {:reply, :ehlo, state}
  end

  @spec client_handle(:system, state :: map) :: {:reply, :ehlo, map, map}
  def client_handle(:system, state) do
    {:reply, :system, System.overview, state}
  end

  @spec client_handle(:about, state :: map) :: {:reply, :about, map, map}
  def client_handle(:about, state) do
    {:reply, :about, Wobserver.about, state}
  end

  @spec client_info(any, state :: map) :: {:noreply, map}
  def client_info(_do, state) do
    {:noreply, state}
  end
end

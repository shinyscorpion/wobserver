defmodule Wobserver.Web.Client do
  @moduledoc ~S"""
  Modules handles WebSocket connects to the client.
  """
  use Wobserver.Web.ClientSocket

  alias Wobserver.Allocator
  alias Wobserver.Table
  alias Wobserver.System
  alias Wobserver.Util.AppInfo
  alias Wobserver.Util.Process
  alias Wobserver.Util.Node.Discovery

  def client_init do
    {:ok, %{}}
  end

  @spec client_handle(:hello, state :: map) :: {:reply, :ehlo, map}
  def client_handle(:hello, state) do
    {:reply, :ehlo, Discovery.local, state}
  end

  @spec client_handle(:system, state :: map) :: {:reply, :ehlo, map, map}
  def client_handle(:system, state) do
    {:reply, :system, System.overview, state}
  end

  @spec client_handle(:about, state :: map) :: {:reply, :about, map, map}
  def client_handle(:about, state) do
    {:reply, :about, Wobserver.about, state}
  end

  @spec client_handle(:application, state :: map) :: {:reply, :about, map, map}
  def client_handle(:application, state) do
    {:reply, :application, AppInfo.list_structured, state}
  end

  @spec client_handle(list(atom), state :: map) :: {:reply, :about, map, map}
  def client_handle([:application, app], state) do
    {:reply, [:application, app], AppInfo.info_structured(app), state}
  end

  @spec client_handle(:process, state :: map) :: {:reply, :about, map, map}
  def client_handle(:process, state) do
    {:reply, :process, AppInfo.process_list, state}
  end

  @spec client_handle(list(atom), state :: map) :: {:reply, :about, map, map}
  def client_handle([:process, process], state) do
    data =
      process
      |> Atom.to_string
      |> Process.info

    {:reply, [:process, process], data, state}
  end

  @spec client_handle(:ports, state :: map) :: {:reply, :about, map, map}
  def client_handle(:ports, state) do
    {:reply, :ports, Wobserver.Port.list, state}
  end

  @spec client_handle(:allocators, state :: map) :: {:reply, :about, map, map}
  def client_handle(:allocators, state) do
    {:reply, :allocators, Allocator.list, state}
  end

  @spec client_handle(:table, state :: map) :: {:reply, :about, map, map}
  def client_handle(:table, state) do
    {:reply, :table, Table.list, state}
  end

  @spec client_handle(list(atom), state :: map) :: {:reply, :about, map, map}
  def client_handle([:table, table], state) do
    data =
      table
      |> Atom.to_string
      |> Table.sanitize
      |> Table.info(true)

    {:reply, [:table, table], data, state}
  end

  @spec client_info(any, state :: map) :: {:noreply, map}
  def client_info(_do, state) do
    {:noreply, state}
  end
end

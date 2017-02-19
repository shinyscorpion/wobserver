defmodule Wobserver.Web.Client do
  @moduledoc ~S"""
  Modules handles WebSocket connects to the client.
  """
  use Wobserver.Web.ClientSocket

  alias Wobserver.Allocator
  alias Wobserver.Page
  alias Wobserver.Table
  alias Wobserver.System
  alias Wobserver.Util.Application
  alias Wobserver.Util.Process
  alias Wobserver.Util.Node.Discovery

  @doc ~S"""
  Starts the websocket client.

  Returns a map as state.
  """
  @spec client_init :: {:ok, map}
  def client_init do
    {:ok, %{}}
  end

  @doc ~S"""
  Handles the `command` given by the websocket interface.

  The current `state` is passed and can be modified.

  Returns a map as state.
  """
  @spec client_handle(atom | list(atom), state :: map) ::
    {:reply, atom | list(atom), map, map}
    | {:reply, atom | list(atom), map}
    | {:noreply, map}
  def client_handle(command, state)

  def client_handle(:hello, state) do
    {:reply, :ehlo, Discovery.local, state}
  end

  def client_handle(:ping, state) do
    {:reply, :pong, state}
  end

  def client_handle(:system, state) do
    {:reply, :system, System.overview, state}
  end

  def client_handle(:about, state) do
    {:reply, :about, Wobserver.about, state}
  end

  def client_handle(:application, state) do
    {:reply, :application, Application.list, state}
  end

  def client_handle([:application, app], state) do
    {:reply, [:application, app], Application.info(app), state}
  end

  def client_handle(:process, state) do
    {:reply, :process, Process.list, state}
  end

  def client_handle([:process, process], state) do
    data =
      process
      |> Atom.to_string
      |> Process.info

    {:reply, [:process, process], data, state}
  end

  def client_handle(:ports, state) do
    {:reply, :ports, Wobserver.Port.list, state}
  end

  def client_handle(:allocators, state) do
    {:reply, :allocators, Allocator.list, state}
  end

  def client_handle(:table, state) do
    {:reply, :table, Table.list, state}
  end

  def client_handle([:table, table], state) do
    data =
      table
      |> Atom.to_string
      |> Table.sanitize
      |> Table.info(true)

    {:reply, [:table, table], data, state}
  end

  def client_handle(:custom, state) do
    {:reply, :custom, Page.list, state}
  end

  def client_handle(custom, state) do
    case Page.call(custom) do
      :page_not_found -> {:noreply, state}
      data -> {:reply, custom, data, state}
    end
  end

  @doc ~S"""
  Handles process messages.

  Should not be used, the `do` is ignored and the `state` is returned unmodified.
  """
  @spec client_info(any, state :: map) :: {:noreply, map}
  def client_info(_do, state) do
    {:noreply, state}
  end
end

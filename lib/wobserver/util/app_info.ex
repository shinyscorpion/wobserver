defmodule Wobserver.Util.AppInfo do
  @moduledoc ~S"""
  Genserver

  TODO:
    - Needs rewrite
    - Needs docs.
    - Needs cleanup.
    - Needs tests.
  """

  use GenServer

  # Api
  @spec list :: list(map)
  def list do
    GenServer.call(__MODULE__, :list)
  end

  @spec info(app :: atom) :: tuple
  def info(app) do
    GenServer.call(__MODULE__, {:info, app})
  end

  @spec list_structured :: list(map)
  def list_structured do
    list()
    |> Enum.map(fn {_pid, _atom, data} -> data end)
    |> Enum.map(
        fn {name, description, version} ->
          %{
            name: name,
            description: to_string(description),
            version: to_string(version),
          }
        end
      )
  end

  @spec info_structured(app :: atom) :: map
  def info_structured(app) do
    {node_info, nodes, links, _} = info(app)

    case node_info do
      [] -> nil
      _ -> structure(nodes, links, node_info)
    end
  end

  @spec process_list :: map
  def process_list do
    :observer_backend.etop_collect(self())
    receive do
      {_, {:etop_info, _, _, _, _, _, _, _stats, processes}} ->
        %{
          #system: stats,
          processes: Enum.map(processes, &process_list_structure/1),
        }
    end
  end

  defp process_list_structure({:etop_proc_info, pid, memory, reductions, init_func, nr1, current_func, message_queue_length}) do
    %{
      pid: "#{inspect pid}",
      init: format_function(init_func),
      current: format_function(current_func),
      memory: memory,
      reductions: reductions,
      nr1: "#{inspect nr1}",
      message_queue_length: message_queue_length,
    }
  end

  defp format_function({module, name, arity}) do
    "#{module}.#{name}/#{arity}"
  end

  defp format_function(name) do
    "#{name}"
  end

  # Callbacks

  @spec start_link(node_name :: node) :: {:ok, pid}
  def start_link(node_name \\ Node.self()) do
    GenServer.start_link(__MODULE__, node_name, name: __MODULE__)
  end

  @spec init(node_name :: node) :: {:ok, map}
  def init(node_name) do
    {:ok, %{node: node_name, appmon: start_appmon(node_name)}}
  end

  @spec handle_call(command :: atom, from :: {pid, any}, state :: map) ::
    {:reply, any, map}
  def handle_call(command, from, state)

  def handle_call(:list, _from, state) do
    {:reply, list_applications(state.appmon, state.node), state}
  end

  def handle_call({:info, app}, _from, state) do
    {:reply, app_info(state.appmon, app), state}
  end

  # Helpers

  defp start_appmon(node_name) do
    {:ok, pid} = :appmon_info.start_link(node_name, self(), [])

    pid
  end

  defp list_applications(appmon, node_name) do
    :appmon_info.app_ctrl(appmon, node_name, true, [])

    receive do
      {:delivery, ^appmon, :app_ctrl, ^node_name, data} -> data
    end
  end

  defp app_info(appmon, application) do
    :appmon_info.app(appmon, application, true, [])

    receive do
      {:delivery, ^appmon, :app, ^application, data} -> data
    end
  end

  defp pmap(collection, func) do
    collection
    |> Enum.map(&(Task.async(fn -> func.(&1) end)))
    |> Enum.map(&Task.await/1)
  end

  defp structure(nodes, links, node_name) do
    pid =
      Enum.find_value(nodes, fn {pid, name} ->
         case name == node_name  do
           true -> pid
           false -> false
         end
      end)

    children =
      links
      |> Enum.filter(fn {parent, _child} -> parent == node_name end)
      #|> Enum.map(fn {_, child} -> structure(nodes, links, child) end)
      |> pmap(fn {_, child} -> structure(nodes, links, child) end)

    %{
      name: to_string(node_name),
      pid: "#{inspect pid}",
      meta: process_meta(pid),
      children: children,
    }
  end

  defp process_meta(nil), do: :unknown

  defp process_meta(pid) do
    data = Process.info(pid)

    %{
      init: format_function(Keyword.get(data, :initial_call)),
      current: format_function(Keyword.get(data, :current_function)),
      status: Keyword.get(data, :status),
      class:
        case Keyword.get(Keyword.get(data,:dictionary), :"$initial_call") do
          {:supervisor, _, _} -> :supervisor
          {:application_master, _, _} -> :application
          _ -> process_status_module(pid)
        end
    }
  end

  defp process_status_module(pid) do
    {:status, ^pid, {:module, class}, _} = :sys.get_status(pid, 100)
    class
  catch
    _, _ -> :unknown
  end
end

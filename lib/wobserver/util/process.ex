defmodule Wobserver.Util.Process do
  @moduledoc ~S"""
  Process

  TODO:
    - Needs docs.
    - Needs cleanup.
    - Needs tests.
  """

  alias Poison.Encoder
  alias Encoder.BitString

  defimpl Encoder, for: PID do
    @spec encode(pid :: pid, options :: any) :: String.t
    def encode(pid, options) do
      pid
      |> inspect
      |> BitString.encode(options)
    end
  end

  @spec string_to_module(module :: String.t) :: atom
  def string_to_module(module) do
    first_letter = String.first(module)

    case String.capitalize(first_letter) do
      ^first_letter ->
        module
        |> String.split(".")
        |> Enum.map(&String.to_atom/1)
        |> Module.concat
      _ ->
        module
        |> String.to_atom
    end
  end

  @spec pid(
    pid :: pid | atom | list | binary | integer | {integer, integer, integer}
  ) :: pid | nil
  def pid(pid)

  def pid(pid) when is_pid(pid), do: pid
  def pid(pid) when is_atom(pid), do: Process.whereis pid
  def pid(pid) when is_integer(pid), do: pid "<0.#{pid}.0>"
  def pid([a, b, c]), do: pid "<#{a}.#{b}.#{c}>"
  def pid(pid) when is_list(pid), do: :erlang.list_to_pid(pid)
  def pid({a, b, c}), do: pid "<#{a}.#{b}.#{c}>"
  def pid("#PID" <> pid), do: pid |> String.to_charlist |> pid()
  def pid(pid = ("<" <> _)), do: pid |> String.to_charlist |> pid()
  def pid(pid) when is_binary(pid), do: pid |> string_to_module() |> pid()
  def pid(_), do: nil

  @spec pid!(
    pid :: pid | list | binary | integer | {integer, integer, integer}
  ) :: pid
  def pid!(pid) do
    case pid(pid) do
      nil -> raise "Can not convert #{inspect pid} to pid."
      p -> p
    end
  end

  @spec info(
    pid :: pid | list | binary | integer | {integer, integer, integer}
  ) :: :error | map
  def info(pid) do
    pid
    |> pid()
    |> process_info()
  end

  defp process_info(nil), do: :error

  defp process_info(pid) do
    case :erlang.process_info(pid) do
      :undefined ->
        :undefined
      data ->
        gc = Keyword.get(data, :garbage_collection, [])
        dictionary = Keyword.get(data, :dictionary);

        %{
          pid: pid,
          registered_name: Keyword.get(data, :registered_name, nil),
          priority: Keyword.get(data, :priority, :normal),
          trap_exit: Keyword.get(data, :trap_exit, false),
          message_queue_len: Keyword.get(data, :message_queue_len, 0),
          error_handler: Keyword.get(data, :error_handler, :none),
          relations: %{
            group_leader: Keyword.get(data, :group_leader, nil),
            ancestors: Keyword.get(dictionary, :"$ancestors", []),
            links: Keyword.get(data, :links, nil),
          },
          meta: meta(data, pid),
          memory: %{
            total: Keyword.get(data, :memory, 0),
            stack_and_heap: Keyword.get(data, :total_heap_size, 0),
            heap_size: Keyword.get(data, :heap_size, 0),
            stack_size: Keyword.get(data, :stack_size, 0),
            gc_min_heap_size: Keyword.get(gc, :min_heap_size, 0),
            gc_full_sweep_after: Keyword.get(gc, :fullsweep_after, 0),
          },
          state: to_string(:io_lib.format("~tp", [(state(pid))])),
        }
    end
  end

  defp meta(data, pid) do
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

  defp state(pid) do
    :sys.get_state(pid, 100)
  catch
    _, _ -> :unknown
  end

  defp process_status_module(pid) do
    {:status, ^pid, {:module, class}, _} = :sys.get_status(pid, 100)
    class
  catch
    _, _ -> :unknown
  end

  defp format_function({module, name, arity}) do
    "#{module}.#{name}/#{arity}"
  end

  defp format_function(name) do
    "#{name}"
  end

end

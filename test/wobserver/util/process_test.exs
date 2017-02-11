defmodule Wobserver.Util.ProcessTest do
  use ExUnit.Case

  alias Wobserver.Util.Process

  defp pid(pid),
    do: "<0.#{pid}.0>" |> String.to_charlist |> :erlang.list_to_pid

  describe "pid" do
    test "returns for pid" do
      assert Process.pid(pid(33)) == pid(33)
    end

    test "returns for integer" do
      assert Process.pid(33) == pid(33)
    end

    test "returns for atom" do
      refute Process.pid(:cowboy_sup) == nil
    end

    test "returns for module" do
      refute Process.pid(Logger) == nil
    end

    test "returns for integer list" do
      assert Process.pid([0, 33, 0]) == pid(33)
    end

    test "returns for chart list" do
      assert Process.pid('<0.33.0>') == pid(33)
    end

    test "returns for integer tuple" do
      assert Process.pid({0, 33, 0}) == pid(33)
    end

    test "returns for string with #PID" do
      refute Process.pid("#PID<0.33.0>") == nil
    end

    test "returns for string without PID" do
      refute Process.pid("<0.33.0>") == nil
    end

    test "returns for string atom" do
      refute Process.pid("cowboy_sup") == nil
    end

    test "returns for string module" do
      refute Process.pid("Logger") == nil
    end

    test "returns for invalid" do
      assert Process.pid(4.5) == nil
    end
  end

  describe "pid!" do
    test "returns for correct value" do
      assert Process.pid!(33) == pid(33)
    end

    test "raised for invalid value" do
      assert_raise ArgumentError, fn -> Process.pid!(nil) end
    end
  end

  describe "list" do
    setup do
      logger_pid = Process.pid(Logger)

      info =
        Process.list
        |> Enum.find(nil, fn x -> x.pid == logger_pid end)

      [logger: info]
    end

    test "returns pid", context do
      %{pid: pid} = context[:logger]

      assert pid == Process.pid(Logger)
    end

    test "returns name", context do
      %{name: name} = context[:logger]

      assert name == Logger
    end

    test "returns init", context do
      %{init: init} = context[:logger]

      assert init == "proc_lib.init_p/5"
    end

    test "returns current", context do
      %{current: current} = context[:logger]

      assert current == "gen_event.fetch_msg/5"
    end

    test "returns memory", context do
      %{memory: memory} = context[:logger]

      assert memory > 0
    end

    test "returns reductions", context do
      %{reductions: reductions} = context[:logger]

      assert reductions > 0
    end

    test "returns message_queue_length", context do
      %{message_queue_length: message_queue_length} = context[:logger]

      assert message_queue_length == 0
    end
  end

  describe "info" do
    test "returns :error for invalid" do
      assert Process.info(nil) == :error
    end

    test "returns pid" do
      %{pid: pid} = Process.info(Logger)

      assert pid == Process.pid(Logger)
    end

    test "returns name" do
      %{registered_name: registered_name} = Process.info(Logger)

      assert registered_name == Logger
    end
    test "returns priority" do
      %{priority: priority} = Process.info(Logger)

      assert priority == :normal
    end

    test "returns trap_exit" do
      %{trap_exit: trap_exit} = Process.info(Logger)

      assert trap_exit
    end

    test "returns message_queue_len" do
      %{message_queue_len: message_queue_len} = Process.info(Logger)

      assert message_queue_len == 0
    end

    test "returns error_handler" do
      %{error_handler: error_handler} = Process.info(Logger)

      assert error_handler == :error_handler
    end

    test "returns meta" do
      %{meta: meta} = Process.info(Logger)

      assert meta
    end
  end

  describe "meta" do
    setup do
      info =
        Logger
        |> Process.pid
        |> Process.meta

      [logger: info]
    end

    test "returns init", context do
      %{init: init} = context[:logger]

      assert init == "proc_lib.init_p/5"
    end

    test "returns current", context do
      %{current: current} = context[:logger]

      assert current == "gen_event.fetch_msg/5"
    end

    test "returns status", context do
      %{status: status} = context[:logger]

      assert status == :waiting
    end

    test "returns class", context do
      %{class: class} = context[:logger]

      assert class == :gen_event
    end
  end

  describe "edge cases" do
    test "init in dictionary" do
      assert Process.initial_call([
        current: Logger,
        status: :testing,
        class: :mock,
        dictionary: [{:"$initial_call", Logger}]
      ]) == Logger
    end
  end
end

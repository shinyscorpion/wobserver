defmodule Wobserver.System.InfoTest do
  use ExUnit.Case

  describe "architecture" do
    test "returns info struct" do
      assert %Wobserver.System.Info{} = Wobserver.System.Info.architecture()
    end

    test "returns values" do
      %Wobserver.System.Info{
        otp_release: otp_release,
        elixir_version: elixir_version,
        erts_version: erts_version,
        system_architecture: system_architecture,
        kernel_poll: kernel_poll,
        smp_support: smp_support,
        threads: threads,
        thread_pool_size: thread_pool_size,
        wordsize_internal: wordsize_internal,
        wordsize_external: wordsize_external
      } = Wobserver.System.Info.architecture()

      assert is_binary(otp_release)
      assert is_binary(elixir_version)
      assert is_binary(erts_version)
      assert is_binary(system_architecture)
      assert is_boolean(kernel_poll)
      assert is_boolean(smp_support)
      assert is_boolean(threads)
      assert is_integer(thread_pool_size)
      assert is_integer(wordsize_internal)
      assert is_integer(wordsize_external)
    end
  end

  test "cpu returns values" do
    %{
      logical_processors: logical_processors,
      logical_processors_online: logical_processors_online,
      logical_processors_available: logical_processors_available,
      schedulers: schedulers,
      schedulers_online: schedulers_online,
      schedulers_available: schedulers_available
    } = Wobserver.System.Info.cpu()

    assert is_integer(logical_processors)
    assert is_integer(logical_processors_online)
    assert is_integer(logical_processors_available) || logical_processors_available == :unknown
    assert is_integer(schedulers)
    assert is_integer(schedulers_online)
    assert is_integer(schedulers_available)
  end
end

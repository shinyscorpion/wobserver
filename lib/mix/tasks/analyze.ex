defmodule Mix.Tasks.Analyze do
  @moduledoc ~S"""
  Analyze wobserver code and exit if errors have been found.
  """

  use Mix.Task

  @shortdoc "Analyze wobserver code and exit if errors have been found."

  @doc ~S"""
  Analyze wobserver code and exit if errors have been found.

  The following steps are performed:
    - `credo` (strict)
    - `dialyzer`
    - `coveralls` (>=90% coverage pass)
  """
  @spec run([binary]) :: any
  def run(_) do
    IO.puts "Running:"
    execute "mix", ["credo", "--strict"]
    execute "mix", ["dialyzer", "--halt-exit-status"]
    execute "mix", ["coveralls.html"], fn output ->
      if !String.contains?(output, "[TOTAL] 100.0%"), do: IO.write output
    end
  end

  @spec execute(String.t, [String.t], fun | nil) :: any
  defp execute(command, options, post_process \\ nil) do
    commands = ["-q", "/dev/null", command]

    label = "\e[1m#{command} #{Enum.join(options, " ")}\e[0m"

    "    "
    |> Kernel.<>(label)
    |> String.pad_trailing(60, " ")
    |> IO.write

    case System.cmd("script", commands ++ options) do
      {output, 0} ->
        IO.puts "\e[32msuccess\e[0m"

        if post_process, do: post_process.(output)
      {output, _} ->
        IO.puts "\e[31mfailed\e[0m"
        IO.puts output
        IO.puts "#{label} \e[31mfailed\e[0m"
        System.halt(1)
    end
  end
end

defmodule Mix.Tasks.Analyze do
  @moduledoc ~S"""
  Analyze wobserver code and exit if errors have been found.
  """

  use Mix.Task

  @shortdoc "Analyze wobserver code and exit if errors have been found."

  @spec execute(String.t, [String.t], boolean) :: any
  defp execute(command, options, show_output \\ false) do
    commands = ["-q", "/dev/null", command]

    label = "\e[1m#{command} #{Enum.join(options, " ")}\e[0m";

    "    "
    |> Kernel.<>(label)
    |> String.pad_trailing(60, " ")
    |> IO.write

    case System.cmd("script", commands ++ options) do
      {output, 0} ->
        IO.puts "\e[32msuccess\e[0m"

        if show_output, do: IO.puts output
      {output, _} ->
        IO.puts "\e[31mfailed\e[0m"
        IO.puts output
        IO.puts "#{label} \e[31mfailed\e[0m"
        System.halt(1)
    end
  end

  @spec run([binary]) :: any
  def run(_) do
    IO.puts "Running:"
    execute "mix", ["credo", "--strict"]
    execute "mix", ["dialyzer", "--halt-exit-status"]
    execute "mix", ["coveralls.html"], true
  end
end

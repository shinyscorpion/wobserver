defmodule Mix.Tasks.Build do
  @moduledoc ~S"""
  Run through all the build steps for wobserver.
  """

  use Mix.Task

  @shortdoc "Run through all the build steps for wobserver."

  @spec execute(String.t, String.t, [String.t]) :: any
  defp execute(label, command, options) do
    label_padded = String.pad_trailing("  #{label}...", 30, " ")
    IO.write label_padded
    case System.cmd(command, options, [stderr_to_stdout: true]) do
      {_, 0} ->
        IO.puts " \e[32msuccess\e[0m"
      {output, _} ->
        IO.puts " \e[31mfailed\e[0m"
        IO.puts output
        System.halt(1)
    end
  end

  @spec run([binary]) :: any
  def run(_) do
    IO.puts "Building \e[44mwobserver\e[0m:"

    execute "Building web assets", "gulp", ["build"]
    execute "Compiling wobserver", "mix", ["compile"]
    execute "Building documentation", "mix", ["docs"]
    execute "Packaging wobserver", "mix", ["hex.build"]

    IO.puts "\n\e[44mwobserver\e[0m packaged."
  end
end

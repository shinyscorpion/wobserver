defmodule Mix.Tasks.Build do
  @moduledoc ~S"""
  Run through all the build steps for wobserver.
  """

  use Mix.Task

  @shortdoc "Run through all the build steps for wobserver."

  @doc ~S"""
  Run through all the build steps for wobserver.

  The following steps are performed:
    - `gulp` (deploy)
    - `building assets.ex`
    - `compile`
    - `docs`
    - `hex.build`
  """
  @spec run([binary]) :: any
  def run(_) do
    IO.puts("Building \e[44mwobserver\e[0m:")

    execute("Building web assets", Path.absname("node_modules/.bin/gulp"), ["deploy"])
    IO.write("  Building asset module...    ")
    pack()
    IO.puts(" \e[32msuccess\e[0m")
    execute("Compiling wobserver", "mix", ["compile"])
    execute("Building documentation", "mix", ["docs"])
    execute("Packaging wobserver", "mix", ["hex.build"])

    IO.puts("\n\e[44mwobserver\e[0m packaged.")
  end

  @spec execute(String.t(), String.t(), [String.t()]) :: any
  defp execute(label, command, options) do
    label_padded = String.pad_trailing("  #{label}...", 30, " ")
    IO.write(label_padded)

    case System.cmd(command, options, stderr_to_stdout: true) do
      {_, 0} ->
        IO.puts(" \e[32msuccess\e[0m")

      {output, _} ->
        IO.puts(" \e[31mfailed\e[0m")
        IO.puts(output)
        System.halt(1)
    end
  end

  defp load_asset(asset) do
    asset
    |> File.read!()
    |> String.replace("\"\"\"", "\\\"\"\"", global: true)
  end

  defp pack do
    html = load_asset("./assets/index.html")
    css = load_asset("./assets/main.css")
    js = load_asset("./assets/app.js")
    license = load_asset("./LICENSE")

    File.write!(
      "./lib/wobserver/assets.ex",
      """
      defmodule Wobserver.Assets do
        @moduledoc false

        @lint false
        @doc false
        @spec html :: String.t
        def html do
          ~S\"""
          #{html}
          \"""
        end
        _ = @lint

        @lint false
        @doc false
        @spec css :: String.t
        def css do
          ~S\"""
          #{css}
          \"""
        end
        _ = @lint

        @lint false
        @doc false
        @spec js :: String.t
        def js do
          ~S\"""
          #{js}
          \"""
        end
        _ = @lint

        @lint false
        @doc false
        @spec license :: String.t
        def license do
          ~S\"""
          #{license}
          \"""
        end
        _ = @lint
      end
      """
    )
  end
end

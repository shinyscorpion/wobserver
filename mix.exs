defmodule Wobserver.Mixfile do
  use Mix.Project

  def project do
    [
      app: :wobserver,
      version: "0.1.4",
      elixir: "~> 1.4",
      description: "Web based metrics, monitoring, and observer.",
      package: package(),
      build_embedded: Mix.env == :prod,
      start_permanent: Mix.env == :prod,
      deps: deps(),
      # Testing
      test_coverage: [tool: ExCoveralls],
      preferred_cli_env: ["coveralls": :test, "coveralls.detail": :test, "coveralls.post": :test, "coveralls.html": :test],
      dialyzer: [ignore_warnings: "dialyzer.ignore-warnings"],
      # Docs
      name: "Wobserver",
      source_url: "https://github.com/shinyscorpion/wobserver",
      homepage_url: "https://github.com/shinyscorpion/wobserver",
      docs: [
        main: "readme",
        extras: ["README.md"],
      ],
    ]
  end

  def package do
    [
      name: :wobserver,
      maintainers: ["Ian Luites"],
      licenses: ["MIT"],
      files: [
        "lib", "mix.exs", "README*", "LICENSE*", # Elixir
        "assets/index.html", "assets/main.css", "assets/app.js", # Web
      ],
      links: %{
        "GitHub" => "https://github.com/shinyscorpion/wobserver",
      },
    ]
  end

  # Configuration for the OTP application
  #
  # Type "mix help compile.app" for more information
  def application do
    # Specify extra applications you'll use from Erlang/Elixir
    [
      extra_applications: [
        :logger,
        :httpoison,
      ],
      mod: {Wobserver.Application, []},]
  end

  # Dependencies can be Hex packages:
  #
  #   {:my_dep, "~> 0.3.0"}
  #
  # Or git/path repositories:
  #
  #   {:my_dep, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"}
  #
  # Type "mix help deps" for more examples and options
  defp deps do
    [
      {:cowboy, "~> 1.0"},
      {:credo, "~> 0.5", only: [:dev, :test]},
      {:dialyxir, "~> 0.4", only: [:dev], runtime: false},
      {:ex_doc, "~> 0.14", only: :dev},
      {:excoveralls, "~> 0.5", only: :test},
      {:ex_doc, "~> 0.14", only: :dev},
      {:httpoison, "~> 0.10.0"},
      {:meck, "~> 0.8.4", only: :test},
      {:plug, "~> 1.3"},
      {:poison, "~> 2.0 or ~> 3.0"},
      {:websocket_client, "~> 1.2"},
    ]
  end
end

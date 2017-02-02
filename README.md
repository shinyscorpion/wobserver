# Wobserver

[![Hex.pm](https://img.shields.io/hexpm/v/wobserver.svg "Hex")](https://hex.pm/packages/wobserver)
[![Hex.pm](https://img.shields.io/badge/docs-v0.0.1-brightgreen.svg "Docs")](https://hexdocs.pm/wobserver)
[![Hex.pm](https://img.shields.io/hexpm/l/wobserver.svg "License")]()

Web based metrics, monitoring, and observer.

## Progress
  - [ ] System
  - [ ] DNS Discovery - Load balancer
  - [ ] Metrics (prometheus)
  - [ ] Load Charts
  - [ ] Memory Allocators
  - [ ] Applications
  - [ ] Processes
  - [ ] Ports
  - [ ] Table Viewer
  - [ ] ~~Trace Overview~~

## Installation

### Hex (package)

Add Wobserver as a dependency to your `mix.exs` file:

```elixir
def deps do
  [{:wobserver, "~> 0.1.0"}]
end
```

and add it to your list of applications:

```elixir
def application do
  [applications: [:wobserver]]
end
```

Then run `mix deps.get` in your shell to fetch the dependencies.

### Build manually

Run the following commands to build the project:
```bash
$ npm install
$ gulp build
$ mix deps.get
```

## License

Wobserver source code is released under [the MIT License](LICENSE).
Check [LICENSE](LICENSE) file for more information.

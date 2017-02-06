# Wobserver

[![Hex.pm](https://img.shields.io/hexpm/v/wobserver.svg "Hex")](https://hex.pm/packages/wobserver)
[![Hex.pm](https://img.shields.io/badge/docs-v0.0.2-brightgreen.svg "Docs")](https://hexdocs.pm/wobserver)
[![Hex.pm](https://img.shields.io/hexpm/l/wobserver.svg "License")]()

Web based metrics, monitoring, and observer.

## Installation

### Hex (package)

Add Wobserver as a dependency to your `mix.exs` file:

```elixir
def deps do
  [{:wobserver, "~> 0.0.2"}]
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

## Configure
### Port
The port can be set in the config by setting `:port` for `:wobserver` to a valid number.
```elixir
config :wobserver,
  port: 80
```

### Node discover
The method used can be set in the config file by setting:
```elixir
config :wobserver,
  discovery: :none
```

The following methods can be used: (default: `:none`)

  - `:none`, just returns the local node.
  - `:dns`, use DNS to search for other nodes.
    The option `discovery_search` needs to be set to filter entries.
  - `:custom`, a function as String.

### Example config
No discovery: (is default)
```elixir
config :wobserver,
  port: 80,
  discovery: :none
```

Using dns as discovery service:
```elixir
config :wobserver,
  port: 80,
  discovery: :dns,
  discovery_search: "google.nl"
```

Using a custom function:
```elixir
config :wobserver,
  port: 80,
  discovery: :custom,
  discovery_search: &MyApp.CustomDiscovery.discover/0
```

Using a anonymous function:
```elixir
config :wobserver,
  port: 80,
  discovery: :custom,
  discovery_search: fn -> [] end
```

Both the custom and anonymous functions can be given as a String, which will get evaluated.

## Progress
  - [X] System
  - [ ] DNS Discovery - Load balancer
  - [ ] Metrics (prometheus)
  - [ ] Load Charts
  - [ ] Memory Allocators
  - [ ] Applications
  - [ ] Processes
  - [ ] Ports
  - [ ] Table Viewer
  - [ ] ~~Trace Overview~~

## License

Wobserver source code is released under [the MIT License](LICENSE).
Check [LICENSE](LICENSE) file for more information.

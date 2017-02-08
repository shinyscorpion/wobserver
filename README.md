# Wobserver

[![Hex.pm](https://img.shields.io/hexpm/v/wobserver.svg "Hex")](https://hex.pm/packages/wobserver)
[![Hex.pm](https://img.shields.io/badge/docs-v0.0.3-brightgreen.svg "Docs")](https://hexdocs.pm/wobserver)
[![Hex.pm](https://img.shields.io/hexpm/l/wobserver.svg "License")]()

Web based metrics, monitoring, and observer.

## Table of contents

* [wobserver](#wobserver)
* [Table of contents](#table-of-contents)
* [Installation](#installation)
    * [Hex](#hex)
    * [Build manually](#build-manually)
* [Usage](#usage)
    * [Browser](#browser)
    * [API](#api)
        * [Remote nodes](#remote-nodes)
        * [System](#system)
    * [Metrics](#usage-metrics)
* [Configuration](#configuration)
    * [Port](#port)
    * [Node Discovery](#node-discovery)
    * [Metrics](#configure-metrics)
        * [Add Metrics](#add-metrics)
        * [Formatting](#formatting-metrics)
* [Progress](#progress)
* [license](#License)


## Installation

### Hex

Add Wobserver as a dependency to your `mix.exs` file:

```elixir
def deps do
  [{:wobserver, "~> 0.0.3"}]
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

## Usage

### Browser
To view the web interface just enter `http://<host>[:<port>]/` in the browser and it should show the `:wobserver` interface.
The default port is 4001, but the port can be changed in the configuration.

### API

The API can be accessed by calling `http://<host>[:<port>]/api/`.
The index will return `404`, but specific endpoints should return results.

#### <a name="remote-nodes"></a> Remote nodes

The API provides a list of remote nodes by calling `http://<host>[:<port>]/api/nodes`.

The API of remote nodes can be accessed by calling the API endpoint and prefixing the node name, host, or host:port.

For example considering the following node list:
```json
[
  {
    "port": 4001,
    "name": "node_prime",
    "local?": true,
    "host": "192.168.5.55"
  },
  {
    "port": 80,
    "name": "remote",
    "local?": false,
    "host": "80.23.1.165"
  }
]
```

The following calls would all work for the first node:
*(`local` is a reserved name that always points to the local node.*)
```bash
http://<host>[:<port>]/api/local/system
http://<host>[:<port>]/api/node_prime/system
http://<host>[:<port>]/api/192.168.5.55/system
http://<host>[:<port>]/api/192.168.5.55:4001/system
```

And these calls would work for the second node:
```bash
http://<host>[:<port>]/api/remote/system
http://<host>[:<port>]/api/80.23.1.165/system
http://<host>[:<port>]/api/80.23.1.165:80/system
```

#### <a name="system"></a> System
The API provides a list of system information by calling `http://<host>[:<port>]/api/system`.

Example:
```json
{
  "statistics": {
    "uptime": 459876,
    "process_total": 122,
    "process_running": 0,
    "process_max": 262144,
    "output": 1259201,
    "input": 12945380
  },
  "memory": {
    "total": 30275576,
    "process": 5242800,
    "ets": 886544,
    "code": 13635797,
    "binary": 288744,
    "atom": 594561
  },
  "cpu": {
    "schedulers_online": 8,
    "schedulers_available": 8,
    "schedulers": 8,
    "logical_processors_online": 8,
    "logical_processors_available": "unknown",
    "logical_processors": 8
  },
  "architecture": {
    "wordsize_internal": 8,
    "wordsize_external": 8,
    "threads": true,
    "thread_pool_size": 10,
    "system_architecture": "x86_64-apple-darwin15.6.0",
    "smp_support": true,
    "otp_release": "19",
    "kernel_poll": false,
    "erts_version": "8.2",
    "elixir_version": "1.4.0"
  }
}
```

### Metrics
Metrics are available by calling `http://<host>[:<port>]/metrics`.

The metrics are by default formatted for [Prometheus](https://prometheus.io/), but can be configured to work with any system.
An explanation of how to configure the metrics format and how to add metrics to the output will be added later.

## Configuration
### Port
The port can be set in the config by setting `:port` for `:wobserver` to a valid number.

#### Example config
```elixir
config :wobserver,
  port: 80
```

### Node Discovery
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

#### Example config
No discovery: *(default)*
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

Using an anonymous function:
```elixir
config :wobserver,
  port: 80,
  discovery: :custom,
  discovery_search: fn -> [] end
```

Both the custom and anonymous functions can be given as a String, which will get evaluated.

### <a name="configure-metrics"></a> Metrics

#### <a name="add-metrics"></a> Add Metrics
t.b.a.

#### <a name="formatting-metrics"></a> Formatting
A custom formatter can be created for output of metrics by implementing the `Wobserver.Util.Metrics.Formatter` behavior.
This custom formatter can be enabled in the configuration file by setting `metric_format`.

For example this configuration:
```elixir
config :wobserver,
  metric_format: JsonFormatter
```

And this simple JSON formatter:
```elixir
defmodule SimpleJsonFormatter do
  @behaviour Wobserver.Util.Metrics.Formatter

  def format_data(name, data, type, help) do
    formatted_data =
      data
      |> Enum.map(fn {value, labels} ->
           %{value: value, labels: Enum.into(labels, %{})}
         end)

    %{
      name: name,
      type: type,
      description: help,
      data: formatted_data
    }
    |> Poison.encode!
  end

  def combine_metrics(metrics) do
    "[" <> Enum.join(metrics,",") <> "]"
  end

  def merge_metrics(metrics) do
    "[" <> Enum.join(metrics,",") <> "]"
  end
end
```

Produce the following output:
```json
[
  [
    {
      "type": "gauge",
      "name": "erlang_vm_used_memory_bytes",
      "description": "Memory usage of the Erlang VM.",
      "data": [
        {
          "value": 654241,
          "labels": {
            "type": "atom",
            "node": "192.168.1.88"
          }
        },
          {
          "value": 503464,
          "labels": {
            "type": "binary",
            "node": "192.168.1.88"
          }
        },
        {
          "value": 14459399,
          "labels": {
            "type": "code",
            "node": "192.168.1.88"
          }
        },
        {
          "value": 2073072,
          "labels": {
            "type": "ets",
            "node": "192.168.1.88"
          }
        },
        {
          "value": 6008488,
          "labels": {
            "type": "process",
            "node": "192.168.1.88"
          }
        }
      ]
    },
    {
      "type": "counter",
      "name": "erlang_vm_used_io_bytes",
      "description": "IO counter for the Erlang VM.",
      "data": [
        {
          "value": 29523254,
          "labels": {
            "type": "input",
            "node": "192.168.1.88"
          }
        },
        {
          "value": 9960593,
          "labels": {
            "type": "output",
            "node": "192.168.1.88"
          }
        }
      ]
    }
  ]
]
```

## Progress
  - [X] System
  - [X] DNS Discovery - Load balancer
  - [X] Metrics (prometheus)
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

# KuzuPyPortEx

Elixir wrapper for a Python process running KuzuDB. It uses the `export` library to call Python functions from Elixir, using a Port.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kuzu_pyport_ex` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kuzu_pyport_ex, "~> 0.1.4"}
  ]
end
```

## Usage

Expects Python to be installed with the kuzu package. Python 3.12 works well.

e.g.

```
uv venv
source .venv/bin/activate
uv pip install kuzu
```

Install the Proxy in your supervision tree:

```elixir
children = [
  KuzuPyPortEx.Proxy
]

opts = [strategy: :one_for_one, name: KuzuPyPortEx.Supervisor]
Supervisor.start_link(children, opts)
```

Then, in your application, you can call the Proxy:

```elixir
KuzuPyPortEx.Proxy.execute("path/to/kuzu/db", "SELECT * FROM users")
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at <https://hexdocs.pm/kuzu_pyport_ex>.


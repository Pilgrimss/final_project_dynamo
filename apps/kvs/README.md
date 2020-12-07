# KVS

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `kvs` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:kvs, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/kvs](https://hexdocs.pm/kvs).

## PBS Test
### T visibility

### Configuration
> 
> Q: 160
> 
> nodes: 8
> 
> N: 3
> 
> readers: 1
> 
> writers: 1
> 
> timeout: 200

### Result

10 * 1000 put_and _get

consistency: [0.75, 0.802, 0.804, 0.805, 0.801, 0.809, 0.808, 0.8, 0.804, 0.805]
time: 26.2 seconds



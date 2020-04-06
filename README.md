# Blitz

## Description

Create blitz clocks for board games.

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `blitz` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:blitz, "~> 0.1.0"}
  ]
end
```

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/blitz](https://hexdocs.pm/blitz).


## Usage examples

```elixir
iex> id = 1
iex> {:ok, clock} = Blitz.start_clock :fischer, id, [1_000, 1_000]
iex> Blitz.list_clocks
iex> Blitz.start clock
iex> Blitz.press clock
iex> Blitz.get_state clock
```
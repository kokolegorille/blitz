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

# alias Blitz.Periods
# p = Periods.Fischer.new 1000, 10
# {:ok, p} = Periods.Period.tick p, 100
# {:ok, p} = Periods.Period.press p


# id = 1
# simple = Periods.Simple.new 30_000
# args = %{id: id, clocks: %{0 => simple, 1 => simple}}
# {:ok, clock} = Blitz.ClockSup.start_worker args


# {:ok, clock} = Blitz.start_clock :fischer, 2, [1_000, 1_000]
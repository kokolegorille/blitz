defmodule Blitz.Periods.Simple do
  @moduledoc """
  Documentation for `Blitz.Periods.Simple`.
  """

  @type miliseconds() :: non_neg_integer()
  @type status() :: :on | :elapsed
  @type t() :: %{
    per_move: miliseconds(),
    #
    remaining: miliseconds(),
    status: status()
  }

  defstruct(
    per_move: nil,
    #
    remaining: nil,
    status: :on
  )

  def new(per_move) do
    %__MODULE__{
      per_move: per_move,
      #
      remaining: per_move
    }
  end
end

defimpl Blitz.Periods.Period, for: Blitz.Periods.Simple do
  def tick(%{status: :elapsed}, _tick_time), do: {:error, "period is elapsed"}
  def tick(%{remaining: remaining} = period, tick_time) do
    new_remaining = remaining - tick_time
    if new_remaining <= 0,
      do: {:ok, %{period | remaining: new_remaining, status: :elapsed}},
      else: {:ok, %{period | remaining: new_remaining}}
  end

  def press(%{status: :elapsed}), do: {:error, "period is elapsed"}
  def press(%{per_move: per_move} = period) do
    {:ok, %{period | remaining: per_move}}
  end
end

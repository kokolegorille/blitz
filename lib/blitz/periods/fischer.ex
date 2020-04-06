defmodule Blitz.Periods.Fischer do
  @moduledoc """
  Documentation for `Blitz.Periods.Fischer`.
  """

  @type miliseconds() :: non_neg_integer()
  @type status() :: :on | :elapsed
  @type t() :: %{
    initial_time: miliseconds(),
    max_time: miliseconds() | nil,
    time_increment: miliseconds(),
    #
    remaining: miliseconds(),
    status: status()
  }

  defstruct(
    initial_time: nil,
    time_increment: nil,
    max_time: nil,
    #
    remaining: nil,
    status: :on
  )

  def new(initial_time, time_increment, max_time \\ nil) do
    %__MODULE__{
      initial_time: initial_time,
      time_increment: time_increment,
      max_time: max_time,
      #
      remaining: initial_time
    }
  end
end

defimpl Blitz.Periods.Period, for: Blitz.Periods.Fischer do
  def tick(%{status: :elapsed}, _tick_time), do: {:error, "period is elapsed"}
  def tick(%{remaining: remaining} = period, tick_time) do
    new_remaining = remaining - tick_time
    if new_remaining <= 0,
      do: {:ok, %{period | remaining: new_remaining, status: :elapsed}},
      else: {:ok, %{period | remaining: new_remaining}}
  end

  def press(%{status: :elapsed}), do: {:error, "period is elapsed"}
  def press(%{remaining: remaining, time_increment: time_increment, max_time: max_time} = period) do
    new_remaining = if max_time,
      do: min(remaining + time_increment, max_time),
      else: remaining + time_increment
    {:ok, %{period | remaining: new_remaining}}
  end
end

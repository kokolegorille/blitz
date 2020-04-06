defmodule Blitz.Periods.Absolute do
  @moduledoc """
  Documentation for `Blitz.Periods.Absolute`.
  """

  @type miliseconds() :: non_neg_integer()
  @type status() :: :on | :elapsed
  @type t() :: %{
    total_time: miliseconds(),
    #
    remaining: miliseconds(),
    status: status()
  }

  defstruct(
    total_time: nil,
    #
    remaining: nil,
    status: :on
  )

  def new(total_time) do
    %__MODULE__{
      total_time: total_time,
      #
      remaining: total_time
    }
  end
end

defimpl Blitz.Periods.Period, for: Blitz.Periods.Absolute do
  def tick(%{status: :elapsed}, _tick_time), do: {:error, "period is elapsed"}
  def tick(%{remaining: remaining} = period, tick_time) do
    new_remaining = remaining - tick_time
    if new_remaining <= 0,
      do: {:ok, %{period | remaining: new_remaining, status: :elapsed}},
      else: {:ok, %{period | remaining: new_remaining}}
  end

  def press(%{status: :elapsed}), do: {:error, "period is elapsed"}
  def press(period), do: {:ok, period}
end

defmodule Blitz.Periods.Simple do
  @moduledoc """
  Documentation for `Blitz.Periods.Simple`.
  """

  @type miliseconds() :: non_neg_integer()
  @type status() :: :on | :elapsed
  @type t() :: %__MODULE__{
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

  @spec new(non_neg_integer()) :: t()
  def new(per_move) do
    %__MODULE__{
      per_move: per_move,
      #
      remaining: per_move
    }
  end
end

defimpl Blitz.Periods.Period, for: Blitz.Periods.Simple do
  alias Blitz.Periods.Simple
  @type miliseconds() :: non_neg_integer()
  @type reason() :: String.t()

  @spec tick(Simple.t(), miliseconds()) :: {:ok, Simple.t()} | {:error, reason()}
  def tick(%Simple{status: :elapsed}, _tick_time), do: {:error, "period is elapsed"}
  def tick(%Simple{remaining: remaining} = period, tick_time) do
    new_remaining = remaining - tick_time
    if new_remaining <= 0,
      do: {:ok, %{period | remaining: new_remaining, status: :elapsed}},
      else: {:ok, %{period | remaining: new_remaining}}
  end

  @spec press(Simple.t()) :: {:ok, Simple.t()} | {:error, reason()}
  def press(%Simple{status: :elapsed}), do: {:error, "period is elapsed"}
  def press(%Simple{per_move: per_move} = period) do
    {:ok, %{period | remaining: per_move}}
  end
end

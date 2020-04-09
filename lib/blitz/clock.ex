defmodule Blitz.Clock do
  @moduledoc """
  Documentation for `Blitz.Clock`.
  This module holds logic for clock.
  """
  require Logger
  alias Blitz.Periods.Period

  @type status() :: :initialized | :running | :paused | :stopped | :error

  @type t() :: %{
    id: term(),
    current: integer(),
    count: integer(),
    number_of_periods: integer(),
    periods: map(),
    status: status()
  }

  defstruct(
    id: nil,
    current: 0,
    count: 0,
    number_of_periods: 2,
    periods: %{},
    status: :initialized
  )

  def new(args) do
    struct(%__MODULE__{}, args)
  end

  def get_state(%__MODULE__{periods: periods} = clock) do
    initial_map = Map.take(clock, ~w(id current count status)a)
    remainings = Enum.reduce(periods, %{}, fn {k, v}, acc ->
      Map.put(acc, k, v.remaining)
    end)
    state = Map.put(initial_map, :remainings, remainings)
    {:ok, state}
  end

  def start(%__MODULE__{status: status} = clock)
  when status in ~w(initialized paused)a do
    {:ok, %{clock | status: :running}}
  end
  def start(%__MODULE__{} = clock), do: log_error(:start, clock)

  def pause(%__MODULE__{status: :running} = clock) do
    {:ok, %{clock | status: :paused}}
  end
  def pause(%__MODULE__{} = clock), do: log_error(:pause, clock)

  def press(%__MODULE__{status: :running} = clock) do
    %{current: current, periods: periods, number_of_periods: number_of_periods, count: count} = clock

    current_period = periods[current]
    case Period.press(current_period) do
      {:ok, period} ->
        new_periods = Map.put(periods, current, period)
        new_current = rem(current + 1, number_of_periods)
        new_count = count + 1
        {:ok, %{clock | periods: new_periods, current: new_current, count: new_count}}
      {:error, _reason} ->
        %{clock | status: :error}
      end
  end
  def press(%__MODULE__{} = clock), do: log_error(:press, clock)

  def stop(%__MODULE__{} = clock) do
    {:ok, %{clock | status: :stopped}}
  end

  def tick(%__MODULE__{status: :running, periods: periods, current: current} = clock, tick_time) do
    current_period = periods[current]

    case Period.tick(current_period, tick_time) do
      {:ok, %{status: :elapsed} = period} ->
        new_periods = Map.put(periods, current, period)
        {:ok, %{clock | periods: new_periods, status: :stopped}}

      {:ok, period} ->
        new_periods = Map.put(periods, current, period)
        {:ok, %{clock | periods: new_periods}}

      {:error, _reason} ->
        %{clock | status: :error}
    end
  end
  def tick(%__MODULE__{} = clock, _tick_time), do: log_error(:tick, clock)

  defp log_error(action, clock) do
    message = "Cannot #{action} for #{inspect clock}"
    Logger.info message
    {:error, message}
  end
end

defmodule Blitz do
  @moduledoc """
  Documentation for `Blitz`.
  This is the main module API.
  """

  alias Blitz.{ClockWkr, ClockSup, Clock, Periods}
  alias Periods.{Fischer, Simple, Absolute}

  @allowed_clock_types ~w(fischer simple absolute)a
  @default_current 0
  @default_number_of_periods 2

  defdelegate get_state(clock), to: ClockWkr
  defdelegate pause(clock), to: ClockWkr
  defdelegate start(clock), to: ClockWkr
  defdelegate press(clock), to: ClockWkr
  defdelegate stop(clock), to: ClockWkr
  defdelegate whereis_name(name), to: ClockWkr

  defdelegate list_clocks(), to: ClockSup

  # Example:
  #     id = 1
  #     {:ok, clock} = Blitz.start_clock :fischer, id, [1_000 * 60 * 3, 10_000], number_of_clocks: 3
  #
  # Possible options:
  #     * current
  #     * number_of_clocks
  #
  def start_clock(type, id, args, opts \\ [])
  def start_clock(type, id, args, opts) when type in @allowed_clock_types do
    case build_clock(type, id, args, opts) do
      {:ok, clock} ->
        case ClockSup.start_worker(%{id: id, clock: clock}) do
          {:ok, pid} ->
            {:ok, pid}
          {:error, {:already_started, pid}} ->
            {:ok, pid}
        end
      {:error, reason} ->
        {:error, reason}
    end
  end
  def start_clock(type, _id, _args, _opts), do: {:error, "unknown clock type #{type}"}

  def build_clock(type, id, args, opts) when type in @allowed_clock_types do
    {:ok, Clock.new(build_params(type, id, args, opts))}
  end
  def build_clock(type, _id, _args, _opts), do: {:error, "unknown clock type #{type}"}

  defp build_params(type, id, args, opts) do
    period = apply(type_to_period(type), :new, args)
    current = Keyword.get(opts, :current, @default_current)
    number_of_periods = Keyword.get(opts, :number_of_periods, @default_number_of_periods)
    periods = Enum.reduce(0..(number_of_periods - 1), %{}, & Map.put(&2, &1, period))
    %{id: id, periods: periods, number_of_periods: number_of_periods, current: current}
  end

  defp type_to_period(:fischer),  do: Fischer
  defp type_to_period(:simple),   do: Simple
  defp type_to_period(:absolute), do: Absolute
end

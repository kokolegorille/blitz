defmodule Blitz do
  @moduledoc """
  Documentation for `Blitz`.
  This is the main module API.
  """

  alias Blitz.{Clock, ClockSup, Periods}
  alias Periods.{Fischer, Simple, Absolute}

  @allowed_clock_types ~w(fischer simple absolute)a
  @default_number_of_clocks 2
  @default_current 0

  defdelegate get_state(clock), to: Clock
  defdelegate pause(clock), to: Clock
  defdelegate start(clock), to: Clock
  defdelegate press(clock), to: Clock
  defdelegate stop(clock), to: Clock

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
    period = apply(type_to_period(type), :new, args)
    current = Keyword.get(opts, :current, @default_current)
    number_of_clocks = Keyword.get(opts, :number_of_clocks, @default_number_of_clocks)
    clocks = Enum.reduce(0..(number_of_clocks - 1), %{}, & Map.put(&2, &1, period))
    worker_args = %{id: id, clocks: clocks, number_of_clocks: number_of_clocks, current: current}

    case ClockSup.start_worker(worker_args) do
      {:ok, pid} ->
        {:ok, pid}
      {:error, {:already_started, pid}} ->
        {:ok, pid}
    end
  end
  def start_clock(type, _id, _args, _opts), do: {:error, "unknown clock type #{type}"}

  defp type_to_period(:fischer),  do: Fischer
  defp type_to_period(:simple),   do: Simple
  defp type_to_period(:absolute), do: Absolute
end

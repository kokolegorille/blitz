defmodule Blitz.ClockWkr do
  @moduledoc """
  Documentation for `Blitz.ClockWkr`.
  This module holds logic for clock worker.
  """
  use GenServer
  require Logger

  alias Registry.Clocks, as: RegClocks
  alias Blitz.{Clock, Manager}

  @tick_time 100  # miliseconds

  @type t() :: %{
    id: term(),
    ticker_ref: identifier(),
    clock: Clock.t(),
  }

  defstruct(
    id: nil,
    ticker_ref: nil,
    clock: nil
  )

  def child_spec(args) do
    %{
      id: __MODULE__,
      start: {__MODULE__, :start_link, args},
      restart: :transient,
      shutdown: 5000,
      type: :worker
    }
  end

  def start_link(args) do
    name = args.id
    GenServer.start_link(__MODULE__, args, name: via_tuple(name))
  end

  def get_state(pid), do: GenServer.call(pid, :get_state)

  def pause(pid), do: GenServer.cast(pid, :pause)

  def start(pid), do: GenServer.cast(pid, :start)

  def press(pid), do: GenServer.cast(pid, :press)

  def stop(pid), do: GenServer.cast(pid, :stop)

  def whereis_name(name) do
    case Registry.lookup(RegClocks, name) do
      [{pid, _ref}] -> pid
      [] -> nil
    end
  end

  @impl GenServer
  def init(args) do
    Logger.info "#{__MODULE__} is starting"
    state = struct(%__MODULE__{}, args)
    {:ok, state}
  end

  # UNCOMMENT FOR AUTOMATIC CLOCK START!

  # @impl GenServer
  # def init(args) do
  #   Logger.info "#{__MODULE__} is starting"
  #   state = struct(%__MODULE__{}, args)
  #   {:ok, state, {:continue, :set_clocks}}
  # end

  # @impl GenServer
  # def handle_continue(:set_clocks, state) do
  #   ticker_ref = Process.send_after(self(), :tick, @tick_time)
  #   {:noreply, %{state | ticker_ref: ticker_ref, status: :running}}
  # end

  @impl GenServer
  def handle_call(:get_state, _from, %{clock: clock} = state) do
    {:ok, reply} = Clock.get_state(clock)
    {:reply, reply, state}
  end

  @impl GenServer
  def handle_cast(:pause, %{ticker_ref: ticker_ref, clock: %{status: :running} = clock} = state)
  when not is_nil(ticker_ref) do
    elapsed = Process.read_timer(ticker_ref)
    Process.cancel_timer(ticker_ref)

    case Clock.tick(clock, elapsed) do
      {:ok, %{status: :stopped} = clock} ->
        stop_and_notify(state, clock)
      {:ok, clock} ->
        {:noreply, %{state | ticker_ref: nil, clock: clock}}
      {:error, reason} ->
        Logger.info "There was an error: #{reason}"
        {:stop, :normal, state}
    end
  end
  def handle_cast(:pause, state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(:start, %{clock: %{status: status} = clock, ticker_ref: nil} = state)
  when status in ~w(initialized paused)a do
    case Clock.start(clock) do
      {:ok, clock} ->
        ticker_ref = Process.send_after(self(), :tick, @tick_time)
        {:noreply, %{state | clock: clock, ticker_ref: ticker_ref}}
      {:error, reason} ->
        Logger.info "There was an error: #{reason}"
        {:stop, :normal, state}
    end

  end
  def handle_cast(:start, state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(:press, %{clock: %{status: :running} = clock, ticker_ref: ticker_ref} = state) do
    elapsed = Process.read_timer(ticker_ref)
    Process.cancel_timer(ticker_ref)

    with {:ok, %{status: status} = clock} when status != :elapsed <- Clock.tick(clock, elapsed),
      {:ok, %{status: status} = clock} when status != :elapsed <- Clock.press(clock) do

      ticker_ref = Process.send_after(self(), :tick, @tick_time)
      {:noreply, %{state | ticker_ref: ticker_ref, clock: clock}}
    else
      {:ok, clock} ->
        stop_and_notify(state, clock)
      {:error, reason} ->
        Logger.info "There was an error: #{reason}"
        {:stop, :normal, state}
    end
  end
  def handle_cast(:press, state), do: {:noreply, state}

  @impl GenServer
  def handle_cast(:stop, %{clock: clock} = state) do
    {:ok, new_clock} = Clock.stop(clock)
    {:stop, :normal, %{state | clock: new_clock}}
  end

  @impl GenServer
  def handle_info(:tick, %{clock: clock} = state) do
    case Clock.tick(clock, @tick_time) do
      {:ok, %{status: :stopped} = clock} ->
        stop_and_notify(state, clock)
      {:ok, clock} ->
        ticker_ref = Process.send_after(self(), :tick, @tick_time)
        {:noreply, %{state | ticker_ref: ticker_ref, clock: clock}}
      {:error, reason} ->
        Logger.info "There was an error: #{reason}"
        {:stop, :normal, state}
    end
  end

  defp via_tuple(name), do: {:via, Registry, {RegClocks, name}}

  defp stop_and_notify(state, clock) do
    new_state = %{state | ticker_ref: nil, clock: clock}
    notify(new_state)
    {:stop, :normal, new_state}
  end

  defp notify(%{clock: clock} = _state) do
    %{id: id, current: current} = clock
    message = %{id: id, elapsed: current}
    GenServer.cast(Manager, {:notify, message})
  end
end

# defmodule Blitz.ClockWkr do
#   @moduledoc """
#   Documentation for `Blitz.ClockWkr`.
#   This module holds logic for clock worker.
#   """
#   use GenServer
#   require Logger

#   alias Registry.Clocks, as: RegClocks
#   alias Blitz.Manager
#   alias Blitz.Periods.Period

#   @tick_time 100  # miliseconds

#   @type status() :: :initialized | :running | :paused | :stopped | :error

#   @type t() :: %{
#     id: term(),
#     ticker_ref: identifier(),
#     current: integer(),
#     count: integer(),
#     number_of_clocks: integer(),
#     clocks: map(),
#     status: status()
#   }

#   defstruct(
#     id: nil,
#     ticker_ref: nil,
#     current: 0,
#     count: 0,
#     number_of_clocks: 2,
#     clocks: %{},
#     status: :initialized
#   )

#   def child_spec(args) do
#     %{
#       id: __MODULE__,
#       start: {__MODULE__, :start_link, args},
#       restart: :transient,
#       shutdown: 5000,
#       type: :worker
#     }
#   end

#   def start_link(args) do
#     name = args.id
#     GenServer.start_link(__MODULE__, args, name: via_tuple(name))
#   end

#   def get_state(clock), do: GenServer.call(clock, :get_state)

#   def pause(clock), do: GenServer.cast(clock, :pause)

#   def start(clock), do: GenServer.cast(clock, :start)

#   def press(clock), do: GenServer.cast(clock, :press)

#   def stop(worker), do: GenServer.cast(worker, :stop)

#   def whereis_name(name) do
#     case Registry.lookup(RegClocks, name) do
#       [{pid, _ref}] -> pid
#       [] -> nil
#     end
#   end

#   @impl GenServer
#   def init(args) do
#     Logger.info "#{__MODULE__} is starting"
#     state = struct(%__MODULE__{}, args)
#     {:ok, state}
#   end

#   # UNCOMMENT FOR AUTOMATIC CLOCK START!

#   # @impl GenServer
#   # def init(args) do
#   #   Logger.info "#{__MODULE__} is starting"
#   #   state = struct(%__MODULE__{}, args)
#   #   {:ok, state, {:continue, :set_clocks}}
#   # end

#   # @impl GenServer
#   # def handle_continue(:set_clocks, state) do
#   #   ticker_ref = Process.send_after(self(), :tick, @tick_time)
#   #   {:noreply, %{state | ticker_ref: ticker_ref, status: :running}}
#   # end

#   @impl GenServer
#   def handle_call(:get_state, _from, %{id: id, clocks: clocks, current: current, count: count, status: status} = state) do
#     initial_map = %{id: id, current: current, count: count, status: status}
#     remainings = Enum.reduce(clocks, %{}, fn {k, v}, acc ->
#       Map.put(acc, k, v.remaining)
#     end)
#     reply = Map.put(initial_map, :remainings, remainings)

#     {:reply, reply, state}
#   end

#   @impl GenServer
#   def handle_cast(:pause, %{status: :running, ticker_ref: ticker_ref, clocks: clocks, current: current} = state)
#   when not is_nil(ticker_ref) do
#     elapsed = Process.read_timer(ticker_ref)
#     Process.cancel_timer(ticker_ref)

#     current_clock = clocks[current]
#     case Period.tick(current_clock, elapsed) do
#       {:ok, %{status: :elapsed} = clock} ->
#         stop_and_notify(state, clock)

#       {:ok, clock} ->
#         new_clocks = Map.put(clocks, current, clock)
#         {:noreply, %{state | ticker_ref: nil, clocks: new_clocks, status: :paused}}

#       {:error, _reason} ->
#         {:stop, :normal, %{state | status: :error}}
#     end
#   end
#   def handle_cast(:pause, state), do: {:noreply, state}

#   @impl GenServer
#   def handle_cast(:start, %{status: status, ticker_ref: nil} = state)
#   when status in ~w(initialized paused)a do
#     ticker_ref = Process.send_after(self(), :tick, @tick_time)
#     {:noreply, %{state | status: :running, ticker_ref: ticker_ref}}
#   end
#   def handle_cast(:start, state), do: {:noreply, state}

#   @impl GenServer
#   def handle_cast(:press, %{status: :running, ticker_ref: ticker_ref, clocks: clocks, current: current} = state) do
#     elapsed = Process.read_timer(ticker_ref)
#     Process.cancel_timer(ticker_ref)
#     current_clock = clocks[current]

#     with {:ok, %{status: status} = clock} when status != :elapsed <- Period.tick(current_clock, elapsed),
#       {:ok, %{status: status} = clock} when status != :elapsed <- Period.press(clock) do

#       new_clocks = Map.put(clocks, current, clock)
#       ticker_ref = Process.send_after(self(), :tick, @tick_time)
#       new_current = rem(current + 1, state.number_of_clocks)
#       new_count = state.count + 1

#       {:noreply, %{state | ticker_ref: ticker_ref, clocks: new_clocks, current: new_current, count: new_count}}
#     else
#       {:ok, clock} ->
#         stop_and_notify(state, clock)

#       {:error, _reason} ->
#         {:stop, :normal, %{state | status: :error}}
#     end
#   end
#   def handle_cast(:press, state), do: {:noreply, state}

#   @impl GenServer
#   def handle_cast(:stop, state), do: {:stop, :normal, %{state | status: :stopped}}

#   @impl GenServer
#   def handle_info(:tick, %{clocks: clocks, current: current} = state) do
#     current_clock = clocks[current]

#     case Period.tick(current_clock, @tick_time) do
#       {:ok, %{status: :elapsed} = clock} ->
#         stop_and_notify(state, clock)

#       {:ok, clock} ->
#         # Logger.debug fn -> "tick..." end

#         new_clocks = Map.put(clocks, current, clock)
#         ticker_ref = Process.send_after(self(), :tick, @tick_time)

#         {:noreply, %{state | ticker_ref: ticker_ref, clocks: new_clocks}}

#       {:error, _reason} ->
#         {:stop, :normal, %{state | status: :error}}
#     end
#   end

#   @impl GenServer
#   def terminate(reason, _state) do
#     Logger.info "#{__MODULE__} stopped : #{inspect(reason)}"
#     :ok
#   end

#   defp via_tuple(name), do: {:via, Registry, {RegClocks, name}}

#   defp stop_and_notify(%{clocks: clocks, current: current} = state, clock) do
#     new_clocks = Map.put(clocks, current, clock)
#     new_state = %{state | status: :stopped, ticker_ref: nil, clocks: new_clocks}
#     notify(new_state)
#     {:stop, :normal, new_state}
#   end

#   defp notify(%{id: id, current: current} = _state) do
#     message = %{id: id, elapsed: current}
#     GenServer.cast(Manager, {:notify, message})
#   end
# end

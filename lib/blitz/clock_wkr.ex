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
    GenServer.start_link(__MODULE__, args, name: via(name))
  end

  def get_state(pid) when is_pid(pid), do: GenServer.call(pid, :get_state)
  def get_state(name), do: GenServer.call(via(name), :get_state)

  def pause(pid) when is_pid(pid), do: GenServer.cast(pid, :pause)
  def pause(name), do: GenServer.cast(via(name), :pause)

  def start(pid) when is_pid(pid), do: GenServer.cast(pid, :start)
  def start(name), do: GenServer.cast(via(name), :start)

  def press(pid) when is_pid(pid), do: GenServer.cast(pid, :press)
  def press(name), do: GenServer.cast(via(name), :press)

  def stop(pid) when is_pid(pid), do: GenServer.cast(pid, :stop)
  def stop(name), do: GenServer.cast(via(name), :stop)

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

    with {:ok, %{status: status} = clock} when status != :elapsed <- Clock.tick(clock, elapsed),
      {:ok, clock} <- Clock.pause(clock) do

      {:noreply, %{state | ticker_ref: nil, clock: clock}}
    else
      {:ok, clock} ->
        stop_and_notify(state, clock)
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
    stop_and_notify(%{state | clock: new_clock}, new_clock)
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

  defp via(name), do: {:via, Registry, {RegClocks, name}}

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

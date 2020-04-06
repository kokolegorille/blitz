defmodule Blitz.Manager do
  @moduledoc """
  Documentation for `Blitz.Manager`.
  This module receive elapsed events from clocks.
  """

  use GenServer
  require Logger
  @name __MODULE__

  def start_link(_),
    do: GenServer.start_link(__MODULE__, %{}, name: @name)

  def stop(), do: GenServer.cast(__MODULE__, :stop)

  @impl GenServer
  def init(args) do
    # Process.flag(:trap_exit, true)
    {:ok, args}
  end

  @impl GenServer
  def handle_cast({:notify, message}, state) do
    Logger.info message

    {:noreply, state}
  end

  @impl GenServer
  def handle_cast(:stop, state), do: {:stop, :normal, %{state | status: :stopped}}

  @impl GenServer
  def terminate(reason, _state) do
    Logger.info "#{__MODULE__} stopped : #{inspect(reason)}"
    :ok
  end
end

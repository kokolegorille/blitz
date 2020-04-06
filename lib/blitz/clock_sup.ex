defmodule Blitz.ClockSup do
  @moduledoc """
  The dynamic supervisor for Clock.
  """

  use DynamicSupervisor
  alias Blitz.Clock

  def start_link(_args),
    do: DynamicSupervisor.start_link(__MODULE__, nil, name: __MODULE__)

  def start_worker(args) do
    DynamicSupervisor.start_child(__MODULE__, {Clock, [args]})
  end

  def init(_args) do
    opts = [strategy: :one_for_one]
    DynamicSupervisor.init(opts)
  end

  def list_clocks do
    __MODULE__
    |> DynamicSupervisor.which_children()
    |> Enum.map(fn {_, pid, _, _} ->
      Clock.get_state(pid)
    end)
  end
end

defmodule Blitz.ClockTest do
  use ExUnit.Case

  alias Blitz.Clock

  describe "A new clock" do
    setup do
      type = :fischer
      id = 1
      args = [1_000, 1_000]
      {:ok, clock} = Blitz.build_clock(type, id, args, [])
      {:ok, clock: clock}
    end

    test "A new clock's status is :initialized", %{clock: clock} do
      assert clock.status == :initialized
    end

    test "A new clock can be started", %{clock: clock} do
      {:ok, clock} = Clock.start(clock)
      assert clock.status == :running
    end

    test "get_state of new clock", %{clock: clock} do
      {:ok, state} = Clock.get_state(clock)
      expected = %{
        count: 0,
        current: 0,
        id: 1,
        remainings: %{0 => 1000, 1 => 1000},
        status: :initialized
      }
      assert state == expected
    end

    test "cannot pause a non running clock", %{clock: clock} do
      assert {:error, _reason} = Clock.pause(clock)
    end
  end

  describe "A running clock" do
    setup do
      type = :fischer
      id = 1
      args = [1_000, 1_000]
      {:ok, clock} = Blitz.build_clock(type, id, args, [])
      {:ok, clock} = Clock.start(clock)
      {:ok, clock: clock}
    end

    test "can tick a running clock", %{clock: clock} do
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, state} = Clock.get_state(clock)
      expected = %{
        count: 0,
        current: 0,
        id: 1,
        remainings: %{0 => 900, 1 => 1000},
        status: :running
      }
      assert state == expected
    end

    test "can pause a running clock", %{clock: clock} do
      assert {:ok, %{status: :paused}} = Clock.pause(clock)
    end

    test "can tick until stopped", %{clock: clock} do
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      {:ok, clock} = Clock.tick(clock, 100)
      assert {:ok, %{status: :stopped} = clock} = Clock.tick(clock, 100)
      assert {:error, _reason} = Clock.tick(clock, 100)
    end

    test "press the clock increase the count", %{clock: clock} do
      {:ok, clock} = Clock.press(clock)
      assert clock.count == 1

      {:ok, clock} = Clock.press(clock)
      {:ok, clock} = Clock.press(clock)
      assert clock.count == 3
    end

    test "press the clock alternate current", %{clock: clock} do
      assert clock.current == 0
      {:ok, clock} = Clock.press(clock)
      assert clock.current == 1
      {:ok, clock} = Clock.press(clock)
      assert clock.current == 0
    end
  end
end

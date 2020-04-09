defmodule Blitz.Notifier do
  require Logger

  def notify(message) do
    Logger.info "Clock has stopped #{inspect message}"
  end
end

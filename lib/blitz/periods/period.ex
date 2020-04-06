defprotocol Blitz.Periods.Period do
  @moduledoc """
  Documentation for `Blitz.Periods.Period` protocol.
  """

  def tick(period, integer)
  def press(period)
end


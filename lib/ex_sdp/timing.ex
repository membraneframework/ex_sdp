defmodule ExSDP.Timing do
  @moduledoc """
  This module represents the Timing field of SDP that specifies
  the start and end time of the session.

  For more details please see [RFC4566 Section 5.9](https://tools.ietf.org/html/rfc4566#section-5.9)
  """
  use Bunch
  @enforce_keys [:start_time, :stop_time]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          start_time: non_neg_integer(),
          stop_time: non_neg_integer()
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_timing}
  def parse(timing) do
    withl split: [start, stop] <- String.split(timing, " "),
          parse_start: {start, ""} <- Integer.parse(start),
          parse_stop: {stop, ""} <- Integer.parse(stop) do
      timing = %__MODULE__{
        start_time: start,
        stop_time: stop
      }

      {:ok, timing}
    else
      split: _ -> {:error, :invalid_timing}
      parse_start: _ -> {:error, :time_nan}
      parse_stop: _ -> {:error, :time_nan}
    end
  end
end

defimpl ExSDP.Serializer, for: ExSDP.Timing do
  def serialize(timing),
    do: "t=" <> Integer.to_string(timing.start_time) <> " " <> Integer.to_string(timing.stop_time)
end
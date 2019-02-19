defmodule Membrane.Protocol.SDP.RepeatTimes do
  use Bunch

  @enforce_keys [:repeat_interval, :active_duration, :offset]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          repeat_interval: non_neg_integer(),
          active_duration: non_neg_integer(),
          offset: non_neg_integer()
        }

  @spec parse(binary()) ::
          {:ok, t()} | {:error, :duration_nan | :interval_nan | :invalid_repeat | :offset_nan}
  def parse(repeat) do
    withl split: [interval, duration, offset] <- String.split(repeat, " "),
          parse_interval: {interval, ""} <- Integer.parse(interval),
          parse_duration: {duration, ""} <- Integer.parse(duration),
          parse_offset: {offset, ""} <- Integer.parse(offset) do
      %__MODULE__{
        repeat_interval: interval,
        active_duration: duration,
        offset: offset
      }
      ~> {:ok, &1}
    else
      split: _ -> {:error, :invalid_repeat}
      parse_interval: _ -> {:error, :interval_nan}
      parse_duration: _ -> {:error, :duration_nan}
      parse_offset: _ -> {:error, :offset_nan}
    end
  end
end

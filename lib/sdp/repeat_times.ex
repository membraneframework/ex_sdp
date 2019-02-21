defmodule Membrane.Protocol.SDP.RepeatTimes do
  use Bunch

  @enforce_keys [:repeat_interval, :active_duration, :offsets]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          repeat_interval: non_neg_integer(),
          active_duration: non_neg_integer(),
          offsets: [non_neg_integer()]
        }

  @spec parse(binary()) ::
          {:ok, t()} | {:error, :duration_nan | :interval_nan | :invalid_repeat | :offset_nan}
  def parse(repeat) do
    withl split: [interval, duration | offsets] <- String.split(repeat, " "),
          parse_interval: {interval, ""} <- Integer.parse(interval),
          parse_duration: {duration, ""} <- Integer.parse(duration),
          parse_offsets: {:ok, offsets} <- parse_offsets(offsets) do
      %__MODULE__{
        repeat_interval: interval,
        active_duration: duration,
        offsets: offsets
      }
      ~> {:ok, &1}
    else
      split: _ -> {:error, :invalid_repeat}
      parse_interval: _ -> {:error, :interval_nan}
      parse_duration: _ -> {:error, :duration_nan}
      parse_offsets: {:error, _} = error -> error
    end
  end

  defp parse_offsets([]), do: {:error, :no_offsets}
  defp parse_offsets(offsets), do: process_offsets(offsets)

  defp process_offsets(offsets, acc \\ [])
  defp process_offsets([], acc), do: {:ok, Enum.reverse(acc)}

  defp process_offsets([offset | rest], acc) do
    case Integer.parse(offset) do
      {offset, ""} -> process_offsets(rest, [offset | acc])
      :error -> {:error, {:invalid_offset, offset}}
    end
  end
end

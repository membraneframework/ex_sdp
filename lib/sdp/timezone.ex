defmodule Membrane.Protocol.SDP.Timezone do
  @moduledoc """
  This module represents SDP Timezone Correction used
  for translating base time for rebroadcasts.

  For more details please see [RFC4566 Section 5.11](https://tools.ietf.org/html/rfc4566#section-5.11)
  """
  @enforce_keys [:adjustment_time, :offset]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          adjustment_time: non_neg_integer(),
          offset: -12..12
        }

  @spec parse(binary()) :: {:ok, [t]} | {:error, :invalid_timezone}
  def parse(timezones) do
    case String.split(timezones, " ") do
      list when rem(length(list), 2) == 0 -> parse_timezones(list)
      _ -> {:error, :invalid_timezone}
    end
  end

  @spec serialize([]) :: binary()
  def serialize([]), do: ""

  def serialize(adjustments), do: "z=" <> Enum.map_join(adjustments, " ", &serialize_timezone/1)

  @spec serialize_timezone(t()) :: binary()
  def serialize_timezone(timezone) do
    serialized_offset =
      if timezone.offset == 0 do
        Integer.to_string(timezone.offset)
      else
        Integer.to_string(timezone.offset) <> "h"
      end

    Integer.to_string(timezone.adjustment_time) <> " " <> serialized_offset
  end

  defp parse_timezones(timezone_corrections) do
    timezone_corrections
    |> Enum.chunk_every(2)
    |> Bunch.Enum.try_map(fn [adjustment_time, offset] ->
      parse_timezone(adjustment_time, offset)
    end)
  end

  defp parse_timezone(adjustment_time, offset) do
    with {adjustment_time, ""} <- Integer.parse(adjustment_time),
         {offset, rest} when rest == "" or rest == "h" <- Integer.parse(offset) do
      timezone = %__MODULE__{
        adjustment_time: adjustment_time,
        offset: offset
      }

      {:ok, timezone}
    else
      _ -> {:error, :invalid_timezone}
    end
  end
end

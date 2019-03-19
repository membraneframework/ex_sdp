defmodule Membrane.Protocol.SDP.RepeatTimes do
  @moduledoc """
  This module represents field of SDP that specifies
  rebroadcasts of a session. Works directly in conjunction
  with timing `t` parameter.

   - active_duration - how long session will last
   - repeat_interval - interval of session rebroadcast
   - offsets - offset between scheduled rebroadcast

  If `start_time` of `t` is set to today 3pm, `active_duration` is set
  to `3h`, `repeat_interval` is set to `14d` and `offsets` are `0 4d`
  then session will be rebroadcasted today at 3pm and on Thursday 3pm
  every two week until `end_time` of param `t`.

  For more details please see [RFC4566 Section 5.10](https://tools.ietf.org/html/rfc4566#section-5.10).
  """

  @enforce_keys [:repeat_interval, :active_duration, :offsets]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          repeat_interval: non_neg_integer(),
          active_duration: non_neg_integer(),
          offsets: [non_neg_integer()]
        }

  @unit_mappings %{
    "d" => 86_400,
    "h" => 3600,
    "m" => 60,
    "s" => 1
  }

  @valid_keys Map.keys(@unit_mappings)

  @type reason ::
          :duration_nan
          | :interval_nan
          | :no_offsets
          | :malformed_repeat
          | {:invalid_offset | :invalid_unit, binary()}

  @spec parse(binary()) :: {:ok, t()} | {:error, reason}
  def parse(repeat) do
    case String.split(repeat, " ") do
      [interval, duration | offsets] = as_list ->
        if compact?(as_list) do
          parse_compact(as_list)
        else
          parse_explicit(interval, duration, offsets)
        end

      _ ->
        {:error, :malformed_repeat}
    end
  end

  defp compact?(parts) do
    Enum.any?(parts, fn time ->
      Enum.any?(@valid_keys, fn unit -> String.ends_with?(time, unit) end)
    end)
  end

  defp parse_explicit(_interval, _duration, []), do: {:error, :no_offsets}

  defp parse_explicit(interval, duration, offsets) do
    with {interval, ""} <- Integer.parse(interval),
         {duration, ""} <- Integer.parse(duration),
         {:ok, offsets} <- process_offsets(offsets) do
      explicit_repeat = %__MODULE__{
        repeat_interval: interval,
        active_duration: duration,
        offsets: offsets
      }

      {:ok, explicit_repeat}
    else
      {:error, _} = error -> error
      _ -> {:error, :malformed_repeat}
    end
  end

  defp process_offsets(offsets, acc \\ [])
  defp process_offsets([], acc), do: {:ok, Enum.reverse(acc)}

  defp process_offsets([offset | rest], acc) do
    case Integer.parse(offset) do
      {offset, ""} when offset >= 0 -> process_offsets(rest, [offset | acc])
      {_, _} -> {:error, {:invalid_offset, offset}}
    end
  end

  defp parse_compact(list) do
    with [_ | _] = result <- decode_compact(list) do
      result
      |> Enum.reverse()
      |> build_compact()
    end
  end

  defp decode_compact(list) do
    Enum.reduce_while(list, [], fn
      "0", acc ->
        {:cont, [0 | acc]}

      elem, acc ->
        case Integer.parse(elem) do
          {value, unit} when unit in @valid_keys ->
            time = value * @unit_mappings[unit]
            {:cont, [time | acc]}

          {_, invalid_unit} ->
            {:halt, {:error, {:invalid_unit, invalid_unit}}}
        end
    end)
  end

  defp build_compact(list)
  defp build_compact([_, _]), do: {:error, :no_offsets}

  defp build_compact([interval, duration | offsets]) do
    compact = %__MODULE__{
      repeat_interval: interval,
      active_duration: duration,
      offsets: offsets
    }

    {:ok, compact}
  end
end

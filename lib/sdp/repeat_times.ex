defmodule Membrane.Protocol.SDP.RepeatTimes do
  use Bunch

  @enforce_keys [:repeat_interval, :active_duration, :offsets]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          repeat_interval: non_neg_integer(),
          active_duration: non_neg_integer(),
          offsets: [non_neg_integer()]
        }

  @unit_mappings %{
    "d" => 86400,
    "h" => 3600,
    "m" => 60,
    "s" => 1
  }

  @valid_keys @unit_mappings |> Map.keys()

  @spec parse(binary()) ::
          {:ok, t()} | {:error, :duration_nan | :interval_nan | :invalid_repeat | :offset_nan}
  def parse(repeat) do
    case String.split(repeat, " ") do
      [interval, duration | offsets] = as_list ->
        if compact?(as_list) do
          parse_compact(as_list)
        else
          parse_absolute(interval, duration, offsets)
        end
        ~> {:ok, &1}

      _ ->
        {:error, :invalid_repeat}
    end
  end

  defp compact?(parts) do
    parts
    |> Enum.all?(fn time ->
      time == "0" or Enum.any?(@valid_keys, fn unit -> String.ends_with?(time, unit) end)
    end)
  end

  defp parse_absolute(interval, duration, offsets) do
    withl parse_interval: {interval, ""} <- Integer.parse(interval),
          parse_duration: {duration, ""} <- Integer.parse(duration),
          parse_offsets: {:ok, offsets} <- parse_offsets(offsets) do
      %__MODULE__{
        repeat_interval: interval,
        active_duration: duration,
        offsets: offsets
      }
    else
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

  defp parse_compact(list) do
    list
    |> decode_compact()
    ~>> (result when is_list(result) ->
           result
           |> Enum.reverse()
           |> case do
             [interval, duration | offsets] ->
               %__MODULE__{
                 repeat_interval: interval,
                 active_duration: duration,
                 offsets: offsets
               }

             _ ->
               {:error, :malformed_repeat}
           end)
  end

  defp decode_compact(list) do
    Enum.reduce_while(list, [], fn elem, acc ->
      case Integer.parse(elem) do
        {value, unit} when unit in @valid_keys ->
          time = value * @unit_mappings[unit]
          {:cont, [time | acc]}

        {0, ""} ->
          {:cont, [0 | acc]}

        _ ->
          {:error, :invalid_format}
          ~> {:halt, &1}
      end
    end)
  end
end

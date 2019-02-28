defmodule Membrane.Protocol.SDP.Timezone do
  @moduledoc """
  This module represents SDP Timezone Correction used
  for translating base time for rebroadcasts.

  For more details please see [RFC4566 Section 5.11](https://tools.ietf.org/html/rfc4566#section-5.11)
  """
  use Bunch
  @enforce_keys [:adjustment_time, :offset]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          adjustment_time: non_neg_integer(),
          offset: binary()
        }

  @spec parse(binary()) :: {:ok, [t]} | {:error, :invalid_timezone}
  def parse(timezones) do
    timezones
    |> String.split(" ")
    |> case do
      list when rem(length(list), 2) == 0 ->
        parse_timezones(list)

      _ ->
        {:error, :invalid_timezone}
    end
  end

  defp parse_timezones(timezone_corrections) do
    timezone_corrections
    |> Enum.chunk_every(2)
    |> Enum.reduce_while([], fn [adjustment_time, offset], acc ->
      adjustment_time
      |> parse_timezone(offset)
      |> case do
        {:ok, timezone} -> {:cont, [timezone | acc]}
        {:error, _} = error -> {:halt, error}
      end
    end)
    ~>> (list when is_list(list) -> list |> Enum.reverse() ~> {:ok, &1})
  end

  defp parse_timezone(adjustment_time, offset) do
    adjustment_time
    |> Integer.parse()
    |> case do
      {adjustment_time, ""} ->
        %__MODULE__{
          adjustment_time: adjustment_time,
          offset: offset
        }
        ~> {:ok, &1}

      _ ->
        {:error, :invalid_timezone}
    end
  end
end

defmodule Membrane.Protocol.SDP.Timezone do
  @moduledoc """
  This module groups multiple SDP Timezone Correction used
  for translating base time for rebroadcasts.
  """
  alias __MODULE__.Correction

  defstruct corrections: []

  @type t :: %__MODULE__{
          corrections: [Correction.t()]
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_timezone}
  def parse(timezones) do
    case String.split(timezones, " ") do
      list when rem(length(list), 2) == 0 -> parse_timezones(list)
      _ -> {:error, :invalid_timezone}
    end
  end

  defp parse_timezones(timezone_corrections) do
    parsed =
      timezone_corrections
      |> Enum.chunk_every(2)
      |> Bunch.Enum.try_map(fn [adjustment_time, offset] ->
        Correction.parse("#{adjustment_time} #{offset}")
      end)

    with {:ok, corrections} when is_list(corrections) <- parsed do
      {:ok, %__MODULE__{corrections: corrections}}
    end
  end
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.Timezone do
  alias Membrane.Protocol.SDP.{Serializer, Timezone}

  def serialize(%Timezone{corrections: []}), do: ""

  def serialize(%Timezone{corrections: corrections}),
    do: "z=" <> Enum.map_join(corrections, " ", &Serializer.serialize/1)
end

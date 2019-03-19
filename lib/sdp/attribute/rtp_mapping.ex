defmodule Membrane.Protocol.SDP.Attribute.RTPMapping do
  @moduledoc """
  This module represents RTP mapping.
  """

  @enforce_keys [:payload_type, :encoding, :clock_rate, :params]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          payload_type: 96..127,
          encoding: binary(),
          clock_rate: non_neg_integer(),
          params: [any()]
        }

  @spec parse(binary(), atom | binary()) ::
          {:ok, t()} | {:error, :invalid_attribute | :invalid_param}
  def parse(mapping, type) do
    with [payload_type, encoding | _] <- String.split(mapping, " "),
         [encoding_name, clock_rate | params] <- String.split(encoding, "/"),
         {payload_type, ""} <- Integer.parse(payload_type),
         {clock_rate, ""} <- Integer.parse(clock_rate) do
      mapping = %__MODULE__{
        payload_type: payload_type,
        encoding: encoding_name,
        clock_rate: clock_rate,
        params: parse_params(type, params)
      }

      {:ok, mapping}
    else
      _ -> {:error, :invalid_attribute}
    end
  end

  defp parse_params(:audio, [raw_channels]) do
    case Integer.parse(raw_channels) do
      {channels_count, ""} -> [{:channels_count, channels_count}]
      _ -> {:error, :invalid_param}
    end
  end

  defp parse_params(:audio, []), do: [{:channels_count, 1}]

  defp parse_params(_, params), do: params
end

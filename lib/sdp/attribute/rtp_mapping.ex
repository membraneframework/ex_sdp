defmodule Membrane.Protocol.SDP.Attribute.RTPMapping do
  @moduledoc """
  This module represents RTP mapping.
  """

  @enforce_keys [:payload_type, :encoding, :clock_rate]
  defstruct @enforce_keys ++ [:params]

  @type t :: %__MODULE__{
          payload_type: 96..127,
          encoding: binary(),
          clock_rate: non_neg_integer(),
          params: non_neg_integer() | nil
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
      {channels, ""} -> channels
      _ -> {:error, :invalid_param}
    end
  end

  defp parse_params(:audio, []), do: 1
  defp parse_params(_, [params]), do: params
  defp parse_params(_, []), do: nil
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.Attribute.RTPMapping do
  alias Membrane.Protocol.SDP.Attribute.RTPMapping

  def serialize(mapping) do
    "rtpmap:" <>
      Integer.to_string(mapping.payload_type) <>
      " " <>
      mapping.encoding <>
      "/" <>
      Integer.to_string(mapping.clock_rate) <> serialize_params(mapping)
  end

  defp serialize_params(%RTPMapping{params: nil}), do: ""
  defp serialize_params(%RTPMapping{params: 1}), do: ""
  defp serialize_params(%RTPMapping{params: params}), do: "/" <> to_string(params)
end

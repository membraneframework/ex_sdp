defmodule ExSDP.Attribute.RTPMapping do
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

  @spec parse(binary(), opts :: []) :: {:ok, t()} | {:error, :invalid_attribute | :invalid_param}
  def parse(mapping, opts) do
    with [payload_type, encoding | _] <- String.split(mapping, " "),
         [encoding_name, clock_rate | params] <- String.split(encoding, "/"),
         {payload_type, ""} <- Integer.parse(payload_type),
         {clock_rate, ""} <- Integer.parse(clock_rate) do
      mapping = %__MODULE__{
        payload_type: payload_type,
        encoding: encoding_name,
        clock_rate: clock_rate,
        params: parse_params(params, opts)
      }

      {:ok, mapping}
    else
      _ -> {:error, :invalid_attribute}
    end
  end

  defp parse_params([channels], media_type: :audio), do: String.to_integer(channels)
  defp parse_params([], media_type: :audio), do: 1
  defp parse_params([], media_type: _media_type), do: nil

  defp parse_params(_params, media_type: _media_type),
    do: raise("Only audio attributes can specify parameters")
end

defimpl String.Chars, for: ExSDP.Attribute.RTPMapping do
  alias ExSDP.Attribute.RTPMapping

  def to_string(mapping) do
    "rtpmap:#{mapping.payload_type} #{mapping.encoding}/#{mapping.clock_rate}#{
      serialize_params(mapping)
    }"
  end

  defp serialize_params(%RTPMapping{params: nil}), do: ""
  defp serialize_params(%RTPMapping{params: 1}), do: ""
  defp serialize_params(%RTPMapping{params: params}), do: "/" <> Kernel.to_string(params)
end

defmodule ExSDP.Bandwidth do
  @moduledoc """
  This module represents the bandwidth, a field of SDP that
  denotes the proposed bandwidth to be used by the session or media.

  For more details please see [RFC4566 Section 5.8](https://tools.ietf.org/html/rfc4566#section-5.8).
  """

  @enforce_keys [:type, :bandwidth]
  defstruct @enforce_keys

  @type type :: :CT | :AS

  @supported_types ["CT", "AS"]

  @type t :: %__MODULE__{
          type: type(),
          bandwidth: non_neg_integer()
        }

  @spec parse(binary()) :: {:error, :invalid_bandwidth} | {:ok, t()}
  def parse(bandwidth) do
    with [type, bandwidth] <- String.split(bandwidth, ":"),
         {:ok, bandwidth} <- parse_bandwidth(bandwidth),
         {:ok, type} <- parse_type(type) do
      bandwidth = %__MODULE__{
        type: type,
        bandwidth: bandwidth
      }

      {:ok, bandwidth}
    else
      _ -> {:error, :invalid_bandwidth}
    end
  end

  defp parse_type(type) when type in @supported_types, do: {:ok, String.to_atom(type)}
  defp parse_type("X-" <> _), do: {:error, :experimental_not_supported}
  defp parse_type(_), do: {:error, :invalid_type}

  defp parse_bandwidth(bandwidth) do
    with {value, ""} <- Integer.parse(bandwidth) do
      {:ok, value}
    end
  end
end

defimpl ExSDP.Serializer, for: ExSDP.Bandwidth do
  def serialize(bandwidth, eol),
    do:
      "b=" <>
        Atom.to_string(bandwidth.type) <> ":" <> Integer.to_string(bandwidth.bandwidth) <> eol
end

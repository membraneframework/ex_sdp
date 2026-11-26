defmodule ExSDP.Bandwidth do
  @moduledoc """
  This module represents the bandwidth, a field of SDP that
  denotes the proposed bandwidth to be used by the session or media.

  For more details please see [RFC4566 Section 5.8](https://tools.ietf.org/html/rfc4566#section-5.8).
  """
  use Bunch.Access

  @enforce_keys [:type, :bandwidth]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          type: type(),
          bandwidth: non_neg_integer()
        }

  @type type :: :CT | :AS | :TIAS | :RS | :RR

  @supported_types ["CT", "AS", "TIAS", "RS", "RR"]

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_bandwidth | :unknown_type}
  def parse(bandwidth) do
    with [type, bandwidth] <- String.split(bandwidth, ":"),
         {bandwidth, ""} <- Integer.parse(bandwidth) do
      if type in @supported_types do
        {:ok, %__MODULE__{type: String.to_atom(type), bandwidth: bandwidth}}
      else
        {:error, :unknown_type}
      end
    else
      _invalid_bandwidth -> {:error, :invalid_bandwidth}
    end
  end
end

defimpl String.Chars, for: ExSDP.Bandwidth do
  @impl true
  def to_string(bandwidth), do: "#{bandwidth.type}:#{bandwidth.bandwidth}"
end

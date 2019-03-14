defmodule Membrane.Protocol.SDP.Bandwidth do
  @moduledoc """
  This module represents bandwidth, field of SDP that
  denotes the proposed bandwidth to be used by the session or media.

  For more details please see [RFC4566 Section 5.8](https://tools.ietf.org/html/rfc4566#section-5.8).
  """
  use Bunch

  @enforce_keys [:type, :bandwidth]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          type: binary(),
          bandwidth: non_neg_integer()
        }

  @spec parse(binary()) :: {:error, :invalid_bandwidth} | {:ok, t()}
  def parse(bandwidth) do
    with [type, bandwidth] <- String.split(bandwidth, ":"),
         {:ok, bandwidth} <- parse_bandwidth(bandwidth) do
      %__MODULE__{
        type: type,
        bandwidth: bandwidth
      }
      ~> {:ok, &1}
    else
      _ ->
        {:error, :invalid_bandwidth}
    end
  end

  defp parse_bandwidth(bandwidth) do
    bandwidth
    |> Integer.parse()
    ~>> ({value, ""} -> {:ok, value})
  end
end

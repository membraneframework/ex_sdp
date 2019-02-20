defmodule Membrane.Protocol.SDP.Bandwidth do
  use Bunch

  @moduledoc """
  https://tools.ietf.org/html/rfc4566#section-5.8
  """

  @enforce_keys [:type, :bandwidth]
  defstruct @enforce_keys

  # TODO: MUST support zero or more bandwidth specs

  @type t :: %__MODULE__{
          type: binary(),
          bandwidth: binary()
        }

  @spec parse(binary()) :: {:error, :invalid_bandwidth} | {:ok, t()}
  def parse(bandwidth) do
    case String.split(bandwidth, ":") do
      [type, bandwidth] ->
        %__MODULE__{
          type: type,
          bandwidth: bandwidth
        }
        ~> {:ok, &1}

      _ ->
        {:error, :invalid_bandwidth}
    end
  end
end

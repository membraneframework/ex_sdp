defmodule Membrane.Protocol.SDP.ConnectionInformation do
  use Bunch

  @moduledoc """
  https://tools.ietf.org/html/rfc4566#section-5.7
  """
  @enforce_keys [:network_type, :address_type, :address]
  defstruct @enforce_keys ++ [:ttl, :count]

  alias Membrane.Protocol.SDP.ConnectionInformation.Address

  @type t :: %__MODULE__{
          network_type: binary(),
          address_type: binary(),
          address: Address.t()
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :einval | :invalid_connection_information}
  def parse(connection_string) do
    withl splitter:
            [nettype, addrtype, connection_address] <- String.split(connection_string, " "),
          address: {:ok, address} <- Address.parse(connection_address) do
      %__MODULE__{
        network_type: nettype,
        address_type: addrtype,
        address: address
      }
      ~> {:ok, &1}
    else
      splitter: _ -> {:error, :invalid_connection_information}
      address: error -> error
    end
  end
end

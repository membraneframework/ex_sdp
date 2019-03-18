defmodule Membrane.Protocol.SDP.Origin do
  @moduledoc """
  This module represents Origin field of SDP that represents
  originator of the session.

  If username is set to `-` the originating host does not support the concept of user IDs.

  For more details please see [RFC4566 Section 5.2](https://tools.ietf.org/html/rfc4566#section-5.2)
  """
  use Bunch

  alias Membrane.Protocol.SDP.ConnectionData

  defstruct [
    :username,
    :session_id,
    :session_version,
    :address
  ]

  @type t :: %__MODULE__{
          username: binary(),
          session_id: binary(),
          session_version: binary(),
          address: ConnectionData.sdp_address()
        }

  @spec parse(binary()) ::
          {:ok, t()} | {:error, :invalid_address | :invalid_origin | :option_nan | :wrong_ttl}
  def parse(origin) do
    with [username, sess_id, sess_version, conn_info] <- String.split(origin, " ", parts: 4),
         {:ok, conn_info} <- ConnectionData.parse(conn_info) do
      origin = %__MODULE__{
        username: username,
        session_id: sess_id,
        session_version: sess_version,
        address: conn_info
      }

      {:ok, origin}
    else
      {:error, :invalid_connection_data} -> {:error, :invalid_origin}
      {:error, _} = error -> error
      _ -> {:error, :invalid_origin}
    end
  end
end

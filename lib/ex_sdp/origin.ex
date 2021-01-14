defmodule ExSDP.Origin do
  @moduledoc """
  This module represents the Origin field of SDP that represents the originator of the session.

  If the username is set to `-` the originating host does not support the concept of user IDs.

  The username MUST NOT contain spaces.

  For more details please see [RFC4566 Section 5.2](https://tools.ietf.org/html/rfc4566#section-5.2)
  """

  alias ExSDP.ConnectionData

  @enforce_keys [
    :username,
    :session_id,
    :session_version,
    :address
  ]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          username: binary(),
          session_id: binary(),
          session_version: binary(),
          # FIXME this cannot be ConnectionData.sdp_address() as it has no ttl field for IPv4
          address: ConnectionData.sdp_address()
        }

  @type reason :: :invalid_address | ConnectionData.reason()

  @spec parse(binary()) :: {:ok, t()} | {:error, reason}
  def parse(origin) do
    with [username, sess_id, sess_version, conn_info] <- String.split(origin, " ", parts: 4),
         {:ok, conn_info} <- ConnectionData.parse(conn_info) do
      username = if username == "-", do: nil, else: username

      origin = %__MODULE__{
        username: username,
        session_id: sess_id,
        session_version: sess_version,
        address: conn_info
      }

      {:ok, origin}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_origin}
    end
  end
end

defimpl String.Chars, for: ExSDP.Origin do
  def to_string(origin) do
    "#{origin.username} #{origin.session_id} #{origin.session_version} #{origin.address}"
  end
end

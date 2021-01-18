defmodule ExSDP.Origin do
  @moduledoc """
  This module represents the Origin field of SDP that represents the originator of the session.

  If the username is set to `-` the originating host does not support the concept of user IDs.

  The username MUST NOT contain spaces.

  For more details please see [RFC4566 Section 5.2](https://tools.ietf.org/html/rfc4566#section-5.2)
  """
  use Bunch.Access

  alias ExSDP.ConnectionData

  @enforce_keys [
    :session_id,
    :session_version,
    :address
  ]
  defstruct [username: "-"] ++ @enforce_keys

  @type t :: %__MODULE__{
          username: binary(),
          session_id: binary(),
          session_version: binary(),
          address: ConnectionData.sdp_address()
        }

  @type reason :: :invalid_address | ConnectionData.reason()

  @doc """
  Returns new `%__MODULE{}` struct. By default:
  * `username` is `-`
  * `session_id` and `session_version` are generated as strings representing random 64 bit numbers
  * `address` is `ExSDP.ConnectionData.IP4` with `127.0.0.1` address
  """
  @spec new(
          username: binary(),
          session_id: binary(),
          session_version: binary(),
          address: ConnectionData.sdp_address()
        ) :: t()
  def new(opts) do
    %__MODULE__{
      username: Keyword.get(opts, :username, "-"),
      session_id: Keyword.get(opts, :session_id, generate_random()),
      session_version: Keyword.get(opts, :session_version, generate_random()),
      address: Keyword.get(opts, :address, %ExSDP.ConnectionData.IP4{value: {127, 0, 0, 1}})
    }
  end

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

  defp generate_random(), do: :crypto.strong_rand_bytes(8) |> :binary.decode_unsigned()
end

defimpl String.Chars, for: ExSDP.Origin do
  def to_string(origin) do
    "#{origin.username} #{origin.session_id} #{origin.session_version} #{origin.address}"
  end
end

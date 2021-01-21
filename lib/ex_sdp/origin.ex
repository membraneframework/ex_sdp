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
          session_id: integer(),
          session_version: integer(),
          address: ConnectionData.sdp_address()
        }

  @type reason :: :invalid_address | ConnectionData.reason()

  @doc """
  Returns new origin struct.

  By default:
  * `username` is `-`
  * `session_id` is random 64 bit number
  * `session_version` is `0`
  * `address` is `ExSDP.ConnectionData.IP4` with `127.0.0.1` address
  """
  @spec new(
          username: binary(),
          session_id: integer(),
          session_version: integer(),
          address: ConnectionData.sdp_address()
        ) :: t()
  def new(opts \\ []) do
    %__MODULE__{
      username: Keyword.get(opts, :username, "-"),
      session_id: Keyword.get(opts, :session_id, generate_random()),
      session_version: Keyword.get(opts, :session_version, 0),
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
        session_id: String.to_integer(sess_id),
        session_version: String.to_integer(sess_version),
        address: conn_info
      }

      {:ok, origin}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_origin}
    end
  end

  @doc """
  Increments `session_version` field.

  Can be used while sending offer/answer again.
  """
  @spec bump_version(t()) :: {:ok, t()}
  def bump_version(origin), do: {:ok, %{origin | session_version: origin.session_version + 1}}

  defp generate_random(), do: :crypto.strong_rand_bytes(8) |> :binary.decode_unsigned()
end

defimpl String.Chars, for: ExSDP.Origin do
  def to_string(origin) do
    "#{origin.username} #{origin.session_id} #{origin.session_version} #{origin.address}"
  end
end

defmodule Membrane.Protocol.SDP.PhoneNumber do
  @moduledoc """
  This module represents Phone Number field of SDP.

  For more details please see [RFC4566 Section 5.6](https://tools.ietf.org/html/rfc4566#section-5.6)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          value: binary()
        }
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.PhoneNumber do
  alias Membrane.Protocol.SDP.PhoneNumber
  def serialize(%PhoneNumber{value: number}), do: "p=" <> number
end

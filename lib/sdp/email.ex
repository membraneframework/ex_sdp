defmodule Membrane.Protocol.SDP.Email do
  @moduledoc """
  This module represents Email Address field of SDP.

  For more details please see [RFC4566 Section 5.6](https://tools.ietf.org/html/rfc4566#section-5.6)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          value: binary()
        }
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.Email do
  alias Membrane.Protocol.SDP.Email
  def serialize(%Email{value: email}), do: "e=" <> email
end

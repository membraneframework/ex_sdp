defmodule ExSDP.Email do
  @moduledoc """
  This module represents the Email Address field of SDP.

  For more details please see [RFC4566 Section 5.6](https://tools.ietf.org/html/rfc4566#section-5.6)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          value: binary()
        }
end

defimpl ExSDP.Serializer, for: ExSDP.Email do
  alias ExSDP.Email
  def serialize(%Email{value: email}), do: "e=" <> email
end

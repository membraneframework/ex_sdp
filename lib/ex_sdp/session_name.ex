defmodule ExSDP.SessionName do
  @moduledoc """
  This module represents the Session Name field of SDP.

  For more details please see [RFC4566 Section 5.3](https://tools.ietf.org/html/rfc4566#section-5.3)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          value: binary()
        }
end

defimpl ExSDP.Serializer, for: ExSDP.SessionName do
  alias ExSDP.SessionName
  def serialize(%SessionName{value: name}), do: "s=" <> name
end

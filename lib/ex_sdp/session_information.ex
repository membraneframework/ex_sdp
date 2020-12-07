defmodule ExSDP.SessionInformation do
  @moduledoc """
  This module represents the Session Information field of SDP.

  For more details please see [RFC4566 Section 5.3](https://tools.ietf.org/html/rfc4566#section-5.3)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          value: binary()
        }

  defimpl ExSDP.Serializer, for: ExSDP.SessionInformation do
    alias ExSDP.SessionInformation
    def serialize(%SessionInformation{value: information}), do: "i=" <> information
  end
end

defmodule Membrane.Protocol.SDP.SessionInformation do
  @moduledoc """
  This module represents the Session Information field of SDP.

  For more details please see [RFC4566 Section 5.3](https://tools.ietf.org/html/rfc4566#section-5.3)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t() :: %__MODULE__{
          value: binary()
        }

  defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.SessionInformation do
    alias Membrane.Protocol.SDP.SessionInformation
    def serialize(%SessionInformation{value: information}), do: "i=" <> information
  end
end

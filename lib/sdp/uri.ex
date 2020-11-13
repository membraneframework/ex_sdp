defmodule Membrane.Protocol.SDP.URI do
  @moduledoc """
  This module represents the URI field of SDP.

  For more details please see [RFC4566 Section 5.5](https://tools.ietf.org/html/rfc4566#section-5.5)
  """
  @enforce_keys [:value]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          value: binary()
        }
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.URI do
  alias Membrane.Protocol.SDP.URI

  def serialize(%URI{value: uri}), do: "u=" <> uri
end

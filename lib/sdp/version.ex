defmodule Membrane.Protocol.SDP.Version do
  @moduledoc """
  This module represents Version field of SDP.

  For more details please see [RFC4566 Section 5.1](https://tools.ietf.org/html/rfc4566#section-5.1)
  """
  defstruct value: 0

  @type t :: %__MODULE__{
          value: non_neg_integer()
        }
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP.Version do
  alias Membrane.Protocol.SDP.Version

  def serialize(%Version{value: version}), do: "v=" <> Integer.to_string(version)
end

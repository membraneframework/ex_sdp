defmodule ExSDP.Version do
  @moduledoc """
  This module represents the Version field of SDP.

  By default, `:value` field is set to `0`.

  For more details please see [RFC4566 Section 5.1](https://tools.ietf.org/html/rfc4566#section-5.1)
  """
  defstruct value: 0

  @type t :: %__MODULE__{
          value: non_neg_integer()
        }
end

defimpl ExSDP.Serializer, for: ExSDP.Version do
  alias ExSDP.Version

  def serialize(%Version{value: version}), do: "v=" <> Integer.to_string(version)
end

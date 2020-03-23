defmodule Membrane.Protocol.SDP.Version do
  @type t() :: non_neg_integer()

  defimpl Membrane.Protocol.SDP.Serializer do
    def serialize(version), do: "v=" <> Integer.to_string(version)
  end
end

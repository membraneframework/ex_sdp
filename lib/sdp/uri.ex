defmodule Membrane.Protocol.SDP.URI do
  @type t() :: binary()

  defimpl Membrane.Protocol.SDP.Serializer do
    def serialize(uri), do: "u=" <> uri
  end
end

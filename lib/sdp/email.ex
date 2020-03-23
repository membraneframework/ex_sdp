defmodule Membrane.Protocol.SDP.Email do
  @type t() :: binary()

  defimpl Membrane.Protocol.SDP.Serializer do
    def serialize(email), do: "e=" <> email
  end
end

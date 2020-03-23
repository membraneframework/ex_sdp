defmodule Membrane.Protocol.SDP.Serializer.SessionName do
  @type t() :: binary()

  defimpl Membrane.Protocol.SDP.Serializer do
    def serialize(session_name), do: "s=" <> session_name
  end
end

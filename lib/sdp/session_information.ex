defmodule Membrane.Protocol.SDP.SessionInformation do
  @type t() :: binary()

  defimpl Membrane.Protocol.SDP.Serializer do
    def serialize(session_information), do: "i=" <> session_information
  end
end

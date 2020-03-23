defmodule Membrane.Protocol.SDP.PhoneNumber do
  @type t() :: binary()

  defimpl Membrane.Protocol.SDP.Serializer do
    def serialize(number), do: "p=" <> number
  end
end

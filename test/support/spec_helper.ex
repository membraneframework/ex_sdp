defmodule Membrane.Support.SpecHelper do
  alias Membrane.Protocol.SDP.Session

  def from_binary(sdp_spec) do
    sdp_spec
    |> String.replace("\n", "\r\n")
  end

  @spec empty_session() :: Session.t()
  def empty_session, do: struct(Session, connection_information: [], attributes: [])
end

defprotocol Membrane.Protocol.SDP.Serializer do
  @doc """
  Serializes struct to SDP string
  """
  @spec serialize(t()) :: binary()
  def serialize(struct)
end

defprotocol ExSDP.Serializer do
  @moduledoc """
  This protocol is responsible for serializing structs into SDP strings.
  """
  @doc """
  Serializes struct to SDP string
  """
  @spec serialize(t(), eol :: binary()) :: binary()
  def serialize(struct, eol \\ "\r\n")
end

defimpl ExSDP.Serializer, for: ExSDP do
  alias ExSDP.{Serializer, Timezone}

  def default_eol(), do: @default_eol

  def serialize(session, eol) do
    """
    v=#{Integer.to_string(session.version)}#{eol}\
    #{Serializer.serialize(session.origin, eol)}\
    #{Serializer.serialize(session.session_name, eol)}\
    #{maybe_serialize(Map.get(session, :session_information), eol)}\
    #{maybe_serialize(Map.get(session, :uri), eol)}\
    #{maybe_serialize(Map.get(session, :email), eol)}\
    #{maybe_serialize(Map.get(session, :phone_number), eol)}\
    #{maybe_serialize(Map.get(session, :connection_data), eol)}\
    #{maybe_serialize(Map.get(session, :bandwidth), eol)}\
    #{maybe_serialize(Map.get(session, :timing), eol)}\
    #{maybe_serialize(Map.get(session, :time_repeats), eol)}\
    #{maybe_serialize(Map.get(session, :time_zones_adjustments), eol)}\
    #{maybe_serialize(Map.get(session, :encryption), eol)}\
    #{maybe_serialize(Map.get(session, :attributes), eol)}\
    #{maybe_serialize(Map.get(session, :media), eol)}\
    """
  end

  def maybe_serialize(nil, _eol), do: ""
  def maybe_serialize([], _eol), do: ""

  def maybe_serialize(sdp, eol) when is_list(sdp),
    do: Enum.map_join(sdp, fn x -> ExSDP.Serializer.serialize(x, eol) end)

  def maybe_serialize(sdp, eol), do: ExSDP.Serializer.serialize(sdp, eol)
end

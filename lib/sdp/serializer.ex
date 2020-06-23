defprotocol Membrane.Protocol.SDP.Serializer do
  @doc """
  Serializes struct to SDP string
  """
  @spec serialize(t()) :: binary()
  def serialize(struct)
end

defimpl Membrane.Protocol.SDP.Serializer, for: Membrane.Protocol.SDP do
  @preffered_eol "\r\n"

  alias Membrane.Protocol.SDP.{Serializer, Timezone}

  def serialize(session) do
    [
      :version,
      :origin,
      :session_name,
      :session_information,
      :uri,
      :email,
      :phone_number,
      :connection_data,
      :bandwidth,
      :timing,
      :time_repeats,
      :time_zones_adjustments,
      :encryption,
      :attributes,
      :media
    ]
    |> Enum.map(&Map.get(session, &1))
    |> Enum.reject(&(&1 == [] or &1 == nil))
    |> Enum.map_join(@preffered_eol, &serialize_field/1)
  end

  defp serialize_field([%Timezone{} | _rest] = adjustments), do: Serializer.serialize(adjustments)

  defp serialize_field(list) when is_list(list),
    do: Enum.map_join(list, @preffered_eol, &Serializer.serialize/1)

  defp serialize_field(value), do: Serializer.serialize(value)
end
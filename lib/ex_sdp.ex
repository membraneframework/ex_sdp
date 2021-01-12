defmodule ExSDP do
  @moduledoc """
  This module represents the SDP Session.

  Its fields directly correspond to those defined in
  [RFC4566](https://tools.ietf.org/html/rfc4566#section-5)
  """
  @enforce_keys [
    :version,
    :origin,
    :session_name
  ]

  @optional_keys [
    :email,
    :encryption,
    :uri,
    :phone_number,
    :session_information,
    :timing,
    :time_zones_adjustments,
    attributes: [],
    bandwidth: [],
    connection_data: [],
    media: [],
    time_repeats: []
  ]

  defstruct @enforce_keys ++ @optional_keys

  alias ExSDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    Parser,
    RepeatTimes,
    Serializer,
    Timezone,
    Timing
  }

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          origin: Origin.t(),
          session_name: binary(),
          session_information: binary() | nil,
          uri: binary() | nil,
          email: binary() | nil,
          phone_number: binary() | nil,
          connection_data: ConnectionData.t(),
          bandwidth: [Bandwidth.t()],
          time_zones_adjustments: Timezone.t(),
          encryption: Encryption.t() | nil,
          attributes: [Attribute.t()],
          timing: Timing.t() | nil,
          time_repeats: [RepeatTimes.t()],
          media: [Media.t()]
        }

  defdelegate parse(text), to: Parser
  defdelegate parse!(text), to: Parser

  @spec new(version :: Version.t(), origin :: Origin.t(), session_name :: SessionName.t()) :: t()
  def new(version, origin, session_name) do
    %__MODULE__{
      version: version,
      origin: origin,
      session_name: session_name
    }
  end

  @spec set_timing(sdp :: t(), timing :: Timing.t()) :: t()
  def set_timing(sdp, timing) do
    Bunch.Struct.put_in(sdp, :timing, timing)
  end

  @spec add_media(sdp :: t(), media :: Media.t() | [Media.t()]) :: t()
  def add_media(sdp, media) do
    media = sdp.media ++ Bunch.listify(media)
    Bunch.Struct.put_in(sdp, :media, media)
  end

  @spec add_attribute(sdp :: t(), attribute :: Attribute.t()) :: t()
  def add_attribute(sdp, attribute) do
    attributes = sdp.attributes ++ [attribute]
    Bunch.Struct.put_in(sdp, :attributes, attributes)
  end
end

defimpl String.Chars, for: ExSDP do
  def to_string(session) do
    import ExSDP.Sigil
    alias ExSDP.Serializer

    ~n"""
    v=#{session.version}
    o=#{session.origin}
    s=#{session.session_name}
    #{Serializer.maybe_serialize("i", Map.get(session, :session_information))}
    #{Serializer.maybe_serialize("u", Map.get(session, :uri))}
    #{Serializer.maybe_serialize("e", Map.get(session, :email))}
    #{Serializer.maybe_serialize("p", Map.get(session, :phone_number))}
    #{Serializer.maybe_serialize("c", Map.get(session, :connection_data))}
    #{Serializer.maybe_serialize("b", Map.get(session, :bandwidth))}
    #{Serializer.maybe_serialize("t", Map.get(session, :timing))}
    #{Serializer.maybe_serialize("r", Map.get(session, :time_repeats))}
    #{Serializer.maybe_serialize("z", Map.get(session, :time_zones_adjustments))}
    #{Serializer.maybe_serialize("k", Map.get(session, :encryption))}
    #{Serializer.maybe_serialize("a", Map.get(session, :attributes))}
    #{Serializer.maybe_serialize("m", Map.get(session, :media))}
    """
  end
end

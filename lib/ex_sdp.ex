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
  defdelegate serialize(session), to: Serializer

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

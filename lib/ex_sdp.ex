defmodule ExSDP do
  @moduledoc """
  This module represents the SDP Session.

  Its fields directly correspond to those defined in
  [RFC4566](https://tools.ietf.org/html/rfc4566#section-5)
  """
  use Bunch.Access

  @enforce_keys [:origin]

  @optional_keys [
    :email,
    :encryption,
    :uri,
    :phone_number,
    :session_information,
    :timing,
    :time_zones_adjustments,
    :connection_data,
    attributes: [],
    bandwidth: [],
    media: [],
    time_repeats: []
  ]

  defstruct [
              version: 0,
              session_name: "-"
            ] ++ @enforce_keys ++ @optional_keys

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
          connection_data: ConnectionData.t() | nil,
          bandwidth: [Bandwidth.t()],
          time_zones_adjustments: Timezone.t() | nil,
          encryption: Encryption.t() | nil,
          attributes: [Attribute.t()],
          timing: Timing.t() | nil,
          time_repeats: [RepeatTimes.t()],
          media: [Media.t()]
        }

  defdelegate parse(text), to: Parser
  defdelegate parse!(text), to: Parser

  @spec new(origin :: binary(), version: non_neg_integer(), session_name: binary()) :: t()
  def new(origin, opts) do
    %__MODULE__{
      version: Keyword.get(opts, :version, 0),
      origin: origin,
      session_name: Keyword.get(opts, :session_name, "-")
    }
  end

  @spec add_media(sdp :: t(), media :: Media.t() | [Media.t()]) :: t()
  def add_media(sdp, media), do: Map.update!(sdp, :media, &(&1 ++ Bunch.listify(media)))

  @spec add_attribute(sdp :: t(), attribute :: Attribute.t()) :: t()
  def add_attribute(sdp, attribute),
    do: Map.update!(sdp, :attributes, &(&1 ++ Bunch.listify(attribute)))
end

defimpl String.Chars, for: ExSDP do
  def to_string(session) do
    import ExSDP.Sigil
    alias ExSDP.Serializer

    ~n"""
    v=#{session.version}
    o=#{session.origin}
    s=#{session.session_name}
    #{Serializer.maybe_serialize("i", session.session_information)}
    #{Serializer.maybe_serialize("u", session.uri)}
    #{Serializer.maybe_serialize("e", session.email)}
    #{Serializer.maybe_serialize("p", session.phone_number)}
    #{Serializer.maybe_serialize("c", session.connection_data)}
    #{Serializer.maybe_serialize("b", session.bandwidth)}
    #{Serializer.maybe_serialize("t", session.timing)}
    #{Serializer.maybe_serialize("r", session.time_repeats)}
    #{Serializer.maybe_serialize("z", session.time_zones_adjustments)}
    #{Serializer.maybe_serialize("k", session.encryption)}
    #{Serializer.maybe_serialize("a", session.attributes)}
    #{Serializer.maybe_serialize("m", session.media)}
    """
  end
end

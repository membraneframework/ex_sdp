defmodule Membrane.Protocol.SDP.Session do
  @moduledoc """
  This module represents SDP Session.

  It fields directly correspond to those defined in
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

  alias Membrane.Protocol.SDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Email,
    Encryption,
    Media,
    Origin,
    PhoneNumber,
    RepeatTimes,
    SessionInformation,
    SessionName,
    Timezone,
    Timing,
    URI,
    Version
  }

  @type t :: %__MODULE__{
          version: Version.t(),
          origin: Origin.t(),
          session_name: SessionName.t(),
          session_information: SessionInformation.t() | nil,
          uri: URI.t() | nil,
          email: Email.t() | nil,
          phone_number: PhoneNumber.t() | nil,
          connection_data: ConnectionData.t(),
          bandwidth: [Bandwidth.t()],
          time_zones_adjustments: Timezone.t(),
          encryption: Encryption.t() | nil,
          attributes: [Attribute.t()],
          timing: Timing.t() | nil,
          time_repeats: [RepeatTimes.t()],
          media: [Media.t()]
        }
end

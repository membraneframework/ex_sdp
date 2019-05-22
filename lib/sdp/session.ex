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
    attributes: [],
    bandwidth: [],
    connection_data: [],
    media: [],
    time_repeats: [],
    time_zones_adjustments: []
  ]

  defstruct @enforce_keys ++ @optional_keys

  alias Membrane.Protocol.SDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    RepeatTimes,
    Timezone,
    Timing
  }

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          origin: Origin.t(),
          session_name: binary(),
          email: binary() | nil,
          encryption: Encryption.t() | nil,
          uri: binary() | nil,
          phone_number: binary() | nil,
          session_information: binary() | nil,
          timing: Timing.t() | nil,
          attributes: [Attribute.t()],
          bandwidth: [Bandwidth.t()],
          connection_data: [ConnectionData.sdp_address()],
          media: [Media.t()],
          time_repeats: [RepeatTimes.t()],
          time_zones_adjustments: [Timezone.t()]
        }
end

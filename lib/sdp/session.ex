defmodule Membrane.Protocol.SDP.Session do
  @enforce_keys [
    :version,
    :origin,
    :session_name
  ]

  @optional_keys [
    # optional
    :session_information,
    # optional
    :uri,
    # optional
    :email,
    # optional
    :phone_number,
    # optional
    :connection_information,
    # optional
    :bandwidth,
    # optional
    :time_zones_adjustments,
    # optional
    :encryption,
    # optional
    :attributes,
    # optional
    :timing,
    # optional
    :time_repeats,
    # optional
    media: []
  ]

  defstruct @enforce_keys ++ @optional_keys

  alias Membrane.Protocol.SDP.{
    ConnectionInformation,
    Bandwidth,
    Encryption,
    Media,
    Timezone,
    Timing,
    Origin
  }

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          origin: Origin.t(),
          session_name: binary(),
          session_information: binary() | nil,
          uri: binary(),
          email: binary() | nil,
          phone_number: binary() | nil,
          connection_information: ConnectionInformation.t(),
          bandwidth: Bandwidth.t(),
          time_zones_adjustments: [Timezone.t()],
          encryption: Encryption.t(),
          attributes: [binary() | {binary(), binary()}],
          timing: Timing.t(),
          time_repeats: binary(),
          media: [Media.t()]
        }

  def fields(), do: @enforce_keys ++ @optional_keys
end

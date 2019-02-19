defmodule Membrane.Protocol.SDP.Session do
  defstruct [
    :version,
    :origin,
    :session_name,
    :session_information,
    :uri,
    # optional
    :email,
    # optional
    :phone_number,
    :connection,
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
    :medias
  ]

  alias Membrane.Protocol.SDP.{
    ConnectionInformation,
    Bandwidth,
    Encryption,
    Media,
    Timezone,
    Timing
  }

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          # TODO replace with struct
          origin: binary(),
          session_name: binary(),
          session_information: binary(),
          uri: binary(),
          email: binary() | nil,
          phone_number: binary() | nil,
          connection: ConnectionInformation.t(),
          bandwidth: Bandwidth.t(),
          time_zones_adjustments: [Timezone.t()],
          encryption: Encryption.t(),
          attributes: [binary() | {binary(), binary()}],
          timing: Timing.t(),
          time_repeats: binary(),
          medias: [Media.t()]
        }
end

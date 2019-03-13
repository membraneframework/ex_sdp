defmodule Membrane.Protocol.SDP.Session do
  @enforce_keys [
    :version,
    :origin,
    :session_name
  ]

  @optional_keys [
    :session_information,
    :uri,
    :email,
    :phone_number,
    {:connection_data, []},
    {:bandwidth, []},
    {:time_zones_adjustments, []},
    :encryption,
    {:attributes, []},
    :timing,
    {:time_repeats, []},
    {:media, []}
  ]

  defstruct @enforce_keys ++ @optional_keys

  alias Membrane.Protocol.SDP.{
    ConnectionData,
    Bandwidth,
    Encryption,
    Media,
    Timezone,
    Timing,
    Origin,
    RepeatTimes
  }

  @type t :: %__MODULE__{
          version: non_neg_integer(),
          origin: Origin.t(),
          session_name: binary(),
          session_information: binary() | nil,
          uri: binary(),
          email: binary() | nil,
          phone_number: binary() | nil,
          connection_data: ConnectionData.t(),
          bandwidth: [Bandwidth.t()],
          time_zones_adjustments: [Timezone.t()],
          encryption: Encryption.t(),
          attributes: [binary() | {binary(), binary()}],
          timing: Timing.t(),
          time_repeats: [RepeatTimes.t()],
          media: [Media.t()]
        }

  @spec fields() :: [atom() | {atom(), []}]
  def fields(), do: @enforce_keys ++ @optional_keys
end

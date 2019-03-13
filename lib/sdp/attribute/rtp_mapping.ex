defmodule Membrane.Protocol.SDP.Attribute.RTPMapping do
  use Bunch

  @enforce_keys [:payload_type, :encoding, :clock_rate, :params]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          payload_type: 0..127,
          encoding: binary(),
          clock_rate: non_neg_integer(),
          params: [any()]
        }

  def parse(mapping) do
    with [ptype, encoding | _] <- String.split(mapping, " "),
         [encoding_name, clock_rate | params] <- String.split(encoding, "/"),
         {ptype, ""} <- Integer.parse(ptype),
         {clock_rate, ""} <- Integer.parse(clock_rate) do
      %__MODULE__{
        payload_type: ptype,
        encoding: encoding_name,
        clock_rate: clock_rate,
        params: params
      }
      ~> {:ok, &1}
    else
      {:error, _} = error -> error
      _ -> {:error, :invalid_attribute}
    end
  end
end

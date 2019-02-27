defmodule Membrane.Protocol.SDP.Encryption do
  @moduledoc """
  This module represents Encryption field of SDP that
  stores encryption key or acquisition method of such key.

  Session key should be present IFF the transport medium
  is secure.
  """
  @enforce_keys [:method]
  defstruct @enforce_keys ++ [:key]

  @type t :: %__MODULE__{
          method: binary(),
          key: binary() | nil
        }

  @spec parse(binary()) :: t()
  def parse(definition) do
    case String.split(definition, ":", parts: 2) do
      [method] -> %__MODULE__{method: method}
      [method, key] -> %__MODULE__{method: method, key: key}
    end
  end
end

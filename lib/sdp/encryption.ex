defmodule Membrane.Protocol.SDP.Encryption do
  @moduledoc """
  This module represents Encryption field of SDP that
  stores encryption key or acquisition method of such key.

  Session key should be present IFF the transport medium
  is secure.

  For more details please see [RFC4566 Section 5.12](https://tools.ietf.org/html/rfc4566#section-5.12)
  """
  @enforce_keys [:method]
  defstruct @enforce_keys ++ [:key]

  @type t :: %__MODULE__{
          method: binary(),
          key: binary() | nil
        }

  @spec parse(binary()) :: t()
  def parse(definition) do
    definition
    |> String.split(":", parts: 2)
    |> case do
      [method] -> %__MODULE__{method: method}
      [method, key] -> %__MODULE__{method: method, key: key}
    end
    |> parse_method()
  end

  defp parse_method(%__MODULE__{method: method} = encryption),
    do: %__MODULE__{encryption | method: method_to_atom(method)}

  defp method_to_atom(method)

  defp method_to_atom("prompt"), do: :prompt
  defp method_to_atom("clear"), do: :clear
  defp method_to_atom("base64"), do: :base64
  defp method_to_atom("uri"), do: :uri
  defp method_to_atom(other), do: other
end

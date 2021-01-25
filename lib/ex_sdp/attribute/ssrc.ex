defmodule ExSDP.Attribute.Ssrc do
  @moduledoc """
  This module represents ssrc (RFC 5576).
  """

  @enforce_keys [:id, :attribute]
  defstruct @enforce_keys ++ [:value]

  @type t :: %__MODULE__{id: non_neg_integer(), attribute: binary(), value: binary() | nil}

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :ssrc

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_ssrc}
  def parse(ssrc) do
    case String.split(ssrc, " ") do
      [id, attribute] ->
        case String.split(attribute, ":") do
          [attribute, value] -> {:ok, %__MODULE__{id: id, attribute: attribute, value: value}}
          [attribute] -> {:ok, %__MODULE__{id: id, attribute: attribute}}
          _ -> {:error, :invalid_ssrc}
        end

      _ ->
        {:error, :invalid_ssrc}
    end
  end
end

defimpl String.Chars, for: ExSDP.Attribute.Ssrc do
  alias ExSDP.Attribute.Ssrc

  def to_string(%Ssrc{id: id, attribute: attribute, value: nil}), do: "ssrc:#{id} #{attribute}"

  def to_string(%Ssrc{id: id, attribute: attribute, value: value}),
    do: "ssrc:#{id} #{attribute}:#{value}"
end

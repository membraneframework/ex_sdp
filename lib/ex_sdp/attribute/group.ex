defmodule ExSDP.Attribute.Group do
  @moduledoc """
  This module represents group (RFC 5888).
  """

  @enforce_keys [:semantics, :mids]
  defstruct @enforce_keys

  @type t :: %__MODULE__{semantics: String.t(), mids: [String.t()]}

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :group

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_group}
  def parse(group) do
    case String.split(group, " ", parts: 2) do
      [_semantics, ""] -> {:error, :invalid_group}
      [semantics, mids] -> {:ok, %__MODULE__{semantics: semantics, mids: String.split(mids, " ")}}
      _ -> {:error, :invalid_group}
    end
  end
end

defimpl String.Chars, for: ExSDP.Attribute.Group do
  alias ExSDP.Attribute.Group

  def to_string(%Group{semantics: _semantics, mids: []}), do: ""

  def to_string(%Group{semantics: semantics, mids: mids}),
    do: "group:#{semantics} #{Enum.join(mids, " ")}"
end

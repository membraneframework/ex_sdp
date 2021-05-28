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
      [semantics] ->
        {:ok, %__MODULE__{semantics: semantics, mids: []}}

      [semantics, mids] ->
        mids = String.split(mids, " ")

        # check against any redundant white spaces
        if Enum.any?(mids, &(String.match?(&1, ~r/\s+/) or &1 == "")) do
          {:error, :invalid_group}
        else
          {:ok, %__MODULE__{semantics: semantics, mids: mids}}
        end

      _ ->
        {:error, :invalid_group}
    end
  end
end

defimpl String.Chars, for: ExSDP.Attribute.Group do
  alias ExSDP.Attribute.Group

  def to_string(%Group{semantics: semantics, mids: mids}),
    do: "group:#{semantics} #{Enum.join(mids, " ")}" |> String.trim()
end

defmodule ExSDP.Serializer do
  @moduledoc """
  Module providing helper functions for serialization.
  """

  @doc """
  Each SDP line is of the following format:
    <type>=<value>
  Function parameters follows this description.
  """
  @spec maybe_serialize(type :: binary(), value :: term()) :: binary()
  def maybe_serialize(_type, nil), do: ""
  def maybe_serialize(_type, []), do: ""

  def maybe_serialize(type, values) when is_list(values),
    do: Enum.map_join(values, "\n", fn value -> maybe_serialize(type, value) end)

  def maybe_serialize(type, {key, value}), do: "#{type}=#{key}:#{value}"

  def maybe_serialize(type, value), do: "#{type}=#{value}"
end

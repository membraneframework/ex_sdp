defmodule ExSDP.Serializer do
  @moduledoc """
  Module providing helper functions for serialization.
  """

  @doc """
  Serializes both sdp lines (<type>=<value>) and sdp parameters (<parameter>=<value>)
  """
  @spec maybe_serialize(type :: binary(), value :: term()) :: binary()
  def maybe_serialize(_type, nil), do: ""
  def maybe_serialize(_type, []), do: ""

  def maybe_serialize(type, values) when is_list(values),
    do: Enum.map_join(values, "\n", fn value -> maybe_serialize(type, value) end)

  def maybe_serialize(type, {key, {frames, sec}}), do: "#{type}=#{key}:#{frames}/#{sec}"

  def maybe_serialize(type, {key, value}), do: "#{type}=#{key}:#{value}"

  def maybe_serialize(type, true), do: "#{type}=1"
  def maybe_serialize(type, false), do: "#{type}=0"
  def maybe_serialize(type, value), do: "#{type}=#{value}"

  def maybe_serialize_hex(_type, nil), do: ""

  def maybe_serialize_hex(type, value),
    do: "#{type}=#{Integer.to_string(value, 16) |> String.downcase()}"
end

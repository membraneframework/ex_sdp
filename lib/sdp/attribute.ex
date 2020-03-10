defmodule Membrane.Protocol.SDP.Attribute do
  @moduledoc """
  This module is responsible for parsing SDP Attributes.
  """
  alias __MODULE__.RTPMapping
  use Bunch.Typespec

  @list_type flag_attributes :: [:recvonly, :sendrecv, :sendonly, :inactive]
  @list_type value_attributes :: [
               :cat,
               :charset,
               :keywds,
               :orient,
               :lang,
               :rtpmap,
               :sdplang,
               :tool,
               :type
             ]

  @list_type numeric_attributes :: [:maxptime, :ptime, :quality]

  @type t ::
          binary()
          | flag_attributes
          | {binary()
             | value_attributes
             | numeric_attributes
             | :framerate, binary()}

  @flag_values @flag_attributes |> Enum.map(&to_string/1)
  @directly_assignable_values @value_attributes |> Enum.map(&to_string/1)
  @numeric_values @numeric_attributes |> Enum.map(&to_string/1)

  @doc """
  Parses SDP Attribute.

  `t:value_attributes/0` and `t:numeric_attributes/0` formatted as `name:value`
  are be parsed as `{name, value}` other values are treated as
  `t:flag_attributes/0`. Known attribute names are converted into atoms.
  """
  @spec parse(binary()) :: {:ok, t} | {:error, atom()}
  def parse(line) do
    line
    |> String.split(":", parts: 2)
    |> handle_known_attribute()
  end

  @spec parse_media_attribute({binary() | atom, binary()}, atom() | binary()) ::
          {:error, :invalid_attribute}
          | {:ok, {atom(), any()}}
  def parse_media_attribute({:rtpmap, value}, media) do
    with {:ok, %RTPMapping{} = mapping} <- RTPMapping.parse(value, media) do
      {:ok, {:rtpmap, mapping}}
    end
  end

  def parse_media_attribute(other, _), do: {:ok, other}

  @spec serialize(t()) :: binary()
  def serialize(attribute) do
    "a=" <> serialize_attribute(attribute)
  end

  defp handle_known_attribute(attr)

  defp handle_known_attribute(["framerate", framerate]) do
    with {:ok, framerate} <- parse_framerate(framerate) do
      {:ok, {:framerate, framerate}}
    end
  end

  defp handle_known_attribute([flag]) when is_binary(flag) and flag in @flag_values do
    {:ok, String.to_atom(flag)}
  end

  defp handle_known_attribute([prop, value])
       when is_binary(prop) and prop in @directly_assignable_values do
    {:ok, {String.to_atom(prop), value}}
  end

  defp handle_known_attribute([prop, value]) when is_binary(prop) and prop in @numeric_values do
    case Integer.parse(value) do
      {number, ""} -> {:ok, {String.to_atom(prop), number}}
      _ -> {:error, :invalid_attribute}
    end
  end

  defp handle_known_attribute([name, value]), do: {:ok, {name, value}}
  defp handle_known_attribute([other]), do: {:ok, other}

  defp parse_framerate(framerate) do
    case Float.parse(framerate) do
      {float_framerate, ""} -> {:ok, float_framerate}
      _ -> parse_compound_framerate(framerate)
    end
  end

  defp parse_compound_framerate(framerate) do
    with {left, "/" <> right} <- Integer.parse(framerate),
         {right, ""} <- Integer.parse(right) do
      {:ok, {left, right}}
    else
      _ -> {:error, :invalid_framerate}
    end
  end

  defp serialize_attribute(attribute) when is_binary(attribute), do: attribute
  defp serialize_attribute(attribute) when is_atom(attribute), do: Atom.to_string(attribute)
  defp serialize_attribute({:rtpmap, mapping}), do: RTPMapping.serialize(mapping)
  defp serialize_attribute({:framerate, value}), do: "framerate:" <> value
  defp serialize_attribute({key, value}), do: key <> ":" <> value
end

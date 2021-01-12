defmodule ExSDP.Attribute do
  @moduledoc """
  This module represents Attributes fields of SDP.
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

  @type key :: binary() | value_attributes() | numeric_attributes() | :framerate | :rtpmap
  @type value :: binary() | flag_attributes()

  @enforce_keys [:value]
  @optional_keys [:key]

  defstruct @enforce_keys ++ @optional_keys

  @type t :: %__MODULE__{key: key(), value: value()}

  @flag_values @flag_attributes |> Enum.map(&to_string/1)
  @directly_assignable_values @value_attributes |> Enum.map(&to_string/1)
  @numeric_values @numeric_attributes |> Enum.map(&to_string/1)

  def new(key, value) do
    %__MODULE__{key: key, value: value}
  end

  def new(value) do
    %__MODULE__{value: value}
  end

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

  @spec parse_media_attribute(t(), atom() | binary()) :: {:error, :invalid_attribute} | {:ok, t()}
  def parse_media_attribute(%__MODULE__{key: :rtpmap, value: value}, media) do
    with {:ok, %RTPMapping{} = mapping} <- RTPMapping.parse(value, media) do
      {:ok, %__MODULE__{key: :rtpmap, value: mapping}}
    end
  end

  @spec parse_media_attribute(t(), atom() | binary()) :: {:error, :invalid_attribute} | {:ok, t()}
  def parse_media_attribute(other, _), do: {:ok, other}

  defp handle_known_attribute(["framerate", framerate]) do
    with {:ok, framerate} <- parse_framerate(framerate) do
      {:ok, %__MODULE__{key: :framerate, value: framerate}}
    end
  end

  defp handle_known_attribute([flag]) when is_binary(flag) and flag in @flag_values do
    {:ok, %__MODULE__{value: String.to_atom(flag)}}
  end

  defp handle_known_attribute([prop, value])
       when is_binary(prop) and prop in @directly_assignable_values do
    {:ok, %__MODULE__{key: String.to_atom(prop), value: value}}
  end

  defp handle_known_attribute([prop, value]) when is_binary(prop) and prop in @numeric_values do
    case Integer.parse(value) do
      {number, ""} -> {:ok, %__MODULE__{key: String.to_atom(prop), value: number}}
      _ -> {:error, :invalid_attribute}
    end
  end

  defp handle_known_attribute([name, value]), do: {:ok, %__MODULE__{key: name, value: value}}
  defp handle_known_attribute([other]), do: {:ok, %__MODULE__{value: other}}

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
end

defimpl String.Chars, for: ExSDP.Attribute do
  alias ExSDP.Attribute

  def to_string(%Attribute{key: nil, value: value}), do: "#{value}"

  def to_string(%Attribute{key: key, value: value}), do: "#{key}:#{value}"
end

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
               :sdplang,
               :tool,
               :type,
               :framerate,
               :maxptime,
               :ptime,
               :quality
             ]

  @type key :: binary() | value_attributes()
  @type value :: binary() | flag_attributes()
  @type t :: __MODULE__.RTPMapping.t() | {key(), value()} | value()

  @doc """
  Parses SDP Attribute line.

  `line` is a string in form of `a=attribute` or `a=attribute:value`.
  `opts` is a keyword list that can contain some information for parsers.

  Unknown attributes keys are returned as strings, known ones as atoms.
  """
  @spec parse(binary(), opts :: []) :: {:ok, t()} | {:error, atom()}
  def parse(line, opts \\ []) do
    [attribute | value] = String.split(line, ":", parts: 2)
    attribute = String.to_atom(attribute)
    do_parse(attribute, List.first(value), opts)
  end

  defp do_parse(flag, nil, _opts) when flag in @flag_attributes, do: {:ok, flag}

  defp do_parse(flag, nil, _opts), do: {:ok, "#{flag}"}

  defp do_parse(:rtpmap, value, opts), do: RTPMapping.parse(value, opts)

  defp do_parse(:framerate, value, _opts) do
    case String.split(value, "/") do
      [framerate] -> {:ok, {:framerate, String.to_float(framerate)}}
      [left, right] -> {:ok, {:framerate, {String.to_integer(left), String.to_integer(right)}}}
    end
  end

  defp do_parse(attribute, value, _opts) when attribute in [:maxptime, :ptime, :quality] do
    case Integer.parse(value) do
      {number, ""} -> {:ok, {attribute, number}}
      _ -> {:error, :invalid_attribute}
    end
  end

  defp do_parse(attribute, value, _opts) when attribute in @value_attributes,
    do: {:ok, {attribute, value}}

  defp do_parse(attribute, value, _opts), do: {:ok, {"#{attribute}", value}}
end

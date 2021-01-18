defmodule ExSDP.Attribute do
  @moduledoc """
  This module represents Attributes fields of SDP.
  """
  use Bunch.Typespec
  use Bunch.Access

  alias __MODULE__.RTPMapping

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

  @flag_attributes_strings @flag_attributes |> Enum.map(&to_string/1)
  @value_attributes_strings @value_attributes |> Enum.map(&to_string/1)

  @type framerate :: float() | {integer(), integer()}
  @type key :: binary() | value_attributes()
  @type value :: binary() | integer() | framerate() | flag_attributes()
  @type t :: __MODULE__.RTPMapping.t() | {key(), value()} | flag_attributes() | binary()

  @doc """
  Parses SDP Attribute line.

  `line` is a string in form of `a=attribute` or `a=attribute:value`.
  `opts` is a keyword list that can contain some information for parsers.

  Unknown attributes keys are returned as strings, known ones as atoms.
  Values for keys `:maxptime`, `:ptime` and `:quality` are converted into `integer()`.
  Values for key `:framerate` is converted into `float()` or tuple of Integers.
  """
  @spec parse(binary(), opts :: []) :: {:ok, t()} | {:error, atom()}
  def parse(line, opts \\ []) do
    [attribute | value] = String.split(line, ":", parts: 2)
    do_parse(attribute, List.first(value), opts)
  end

  defp do_parse(flag, nil, _opts) when flag in @flag_attributes_strings,
    do: {:ok, String.to_atom(flag)}

  defp do_parse(flag, nil, _opts), do: {:ok, flag}

  defp do_parse("rtpmap", value, opts), do: RTPMapping.parse(value, opts)

  defp do_parse("framerate", value, _opts) do
    case String.split(value, "/") do
      [framerate] -> {:ok, {:framerate, String.to_float(framerate)}}
      [left, right] -> {:ok, {:framerate, {String.to_integer(left), String.to_integer(right)}}}
    end
  end

  defp do_parse(attribute, value, _opts) when attribute in ["maxptime", "ptime", "quality"] do
    case Integer.parse(value) do
      {number, ""} -> {:ok, {String.to_atom(attribute), number}}
      _ -> {:error, :invalid_attribute}
    end
  end

  defp do_parse(attribute, value, _opts) when attribute in @value_attributes_strings,
    do: {:ok, {String.to_atom(attribute), value}}

  defp do_parse(attribute, value, _opts), do: {:ok, {attribute, value}}
end

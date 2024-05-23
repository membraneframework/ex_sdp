defmodule ExSDP.Utils do
  @moduledoc false

  alias ExSDP.{Attribute, Media}

  alias ExSDP.Attribute.{
    Extmap,
    FMTP,
    Group,
    MSID,
    RID,
    RTCPFeedback,
    RTPMapping,
    Simulcast,
    SSRC,
    SSRCGroup
  }

  # For searching struct attributes by atoms
  @struct_attr_keys %{
    :extmap => Extmap,
    :fmtp => FMTP,
    :group => Group,
    :msid => MSID,
    :rtcp_feedback => RTCPFeedback,
    :rtpmap => RTPMapping,
    :ssrc => SSRC,
    :ssrc_group => SSRCGroup,
    :simulcast => Simulcast,
    :rid => RID
  }

  @spec get_attribute(sdp_or_media :: ExSDP.t() | Media.t(), Attribute.key()) ::
          Attribute.t() | nil
  def get_attribute(sdp_or_media, key) do
    key = Map.get(@struct_attr_keys, key, key)

    sdp_or_media.attributes
    |> Enum.find(fn
      %module{} -> module == key
      {k, _v} -> k == key
      # for flag attributes
      k -> k == key
    end)
  end

  @spec get_attributes(sdp_or_media :: ExSDP.t() | Media.t(), Attribute.key()) :: [Attribute.t()]
  def get_attributes(sdp_or_media, key) do
    key = Map.get(@struct_attr_keys, key, key)

    sdp_or_media.attributes
    |> Enum.filter(fn
      %module{} -> module == key
      {k, _v} -> k == key
      # for flag attributes
      k -> k == key
    end)
  end

  @spec delete_attributes(ExSDP.t() | ExSDP.Media.t(), [Attribute.key()]) ::
          ExSDP.t() | ExSDP.Media.t()
  def delete_attributes(sdp_or_mline, keys) when is_list(keys) do
    keys = Enum.map(keys, fn key -> Map.get(@struct_attr_keys, key, key) end)

    new_attrs =
      Enum.reject(sdp_or_mline.attributes, fn
        %module{} -> module in keys
        {k, _v} -> k in keys
        # flag attributes
        k -> k in keys
      end)

    Map.put(sdp_or_mline, :attributes, new_attrs)
  end

  @spec split(String.t(), String.t() | [String.t()] | :binary.cp() | Regex.t(), any) ::
          {:error, :too_few_fields} | {:ok, [String.t()]}
  def split(origin, delim, expected_len) do
    split = String.split(origin, delim, parts: expected_len)
    if length(split) == expected_len, do: {:ok, split}, else: {:error, :too_few_fields}
  end

  @spec parse_payload_type(binary) :: {:ok, 0..127} | {:errror, :invalid_pt}
  def parse_payload_type(pt_string) do
    case Integer.parse(pt_string) do
      {pt, ""} when pt >= 0 and pt <= 127 -> {:ok, pt}
      _otherwise -> {:error, :invalid_pt}
    end
  end

  @spec parse_numeric_string(binary) :: {:error, :string_nan} | {:ok, integer}
  def parse_numeric_string(string) do
    case Integer.parse(string) do
      {number, ""} -> {:ok, number}
      _string_nan -> {:error, :string_nan}
    end
  end

  @spec parse_numeric_hex_string(binary) :: {:error, :string_not_hex} | {:ok, integer}
  def parse_numeric_hex_string(string) do
    case Integer.parse(string, 16) do
      {number, ""} -> {:ok, number}
      _string_not_hex -> {:error, :string_not_hex}
    end
  end

  @spec parse_numeric_bool_string(binary) :: {:error, :string_not_0_nor_1} | {:ok, boolean}
  def parse_numeric_bool_string(string) do
    case Integer.parse(string) do
      {0, ""} -> {:ok, false}
      {1, ""} -> {:ok, true}
      _string_not_0_nor_1 -> {:error, :string_not_0_nor_1}
    end
  end

  @spec parse_sprop_parameter_sets(binary) ::
          {:error, :invalid_sprop_parameter_sets} | {:ok, %{sps: binary, pps: binary}}
  def parse_sprop_parameter_sets(string) do
    result =
      String.split(string, ",", parts: 2)
      |> Enum.zip([:sps, :pps])
      |> Map.new(fn {encoded, type} ->
        decoded =
          case Base.decode64(encoded) do
            {:ok, decoded} -> decoded
            :error -> nil
          end

        {type, decoded}
      end)

    if Map.get(result, :sps) && Map.get(result, :pps) do
      {:ok, result}
    else
      {:error, :invalid_sprop_parameter_sets}
    end
  end

  @spec parse_sprop_ps(binary()) :: {:error, :invalid_ps} | {:ok, [binary()]}
  def parse_sprop_ps(pss) do
    pss
    |> String.split(",")
    |> Enum.reduce_while({:ok, []}, fn parameter_set, {:ok, acc} ->
      case Base.decode64(parameter_set) do
        {:ok, decoded} -> {:cont, {:ok, acc ++ [decoded]}}
        :error -> {:halt, {:error, :invalid_ps}}
      end
    end)
  end
end

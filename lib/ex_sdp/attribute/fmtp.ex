defmodule ExSDP.Attribute.FMTP do
  @moduledoc """
  This module represents fmtp (RFC 5576).

  Parameters for H264 (not all, RFC 6184), VP8, VP9 and OPUS (RFC 7587) are currently supported.
  """
  alias ExSDP.Utils

  @enforce_keys [:pt]
  defstruct @enforce_keys ++
              [
                # H264
                :profile_level_id,
                :level_asymmetry_allowed,
                :packetization_mode,
                :max_mbps,
                :max_smbps,
                :max_fs,
                :max_dpb,
                :max_br,
                # OPUS
                :maxaveragebitrate,
                :maxplaybackrate,
                :minptime,
                :stereo,
                :cbr,
                :useinbandfec,
                :usedtx,
                # VP8/9
                :profile_id,
                :max_fr
              ]

  @type t :: %__MODULE__{
          profile_level_id: non_neg_integer() | nil,
          max_mbps: non_neg_integer() | nil,
          max_smbps: non_neg_integer() | nil,
          max_fs: non_neg_integer() | nil,
          max_dpb: non_neg_integer() | nil,
          max_br: non_neg_integer() | nil,
          level_asymmetry_allowed: boolean() | nil,
          packetization_mode: non_neg_integer() | nil,
          # OPUS
          maxaveragebitrate: non_neg_integer() | nil,
          maxplaybackrate: non_neg_integer() | nil,
          minptime: non_neg_integer() | nil,
          stereo: boolean() | nil,
          cbr: boolean() | nil,
          useinbandfec: boolean() | nil,
          usedtx: boolean() | nil,
          # VP8/9
          profile_id: non_neg_integer() | nil,
          max_fr: non_neg_integer() | nil
        }

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :fmtp

  @typedoc """
  Reason of parsing failure.
  """
  @type reason :: :unsupported_parameter | :string_nan | :string_not_hex | :string_not_0_nor_1

  @spec parse(binary()) :: {:ok, t()} | {:error, reason()}
  def parse(fmtp) do
    [pt, rest] = String.split(fmtp, " ")
    fmtp = %__MODULE__{pt: String.to_integer(pt)}
    params = String.split(rest, ";")
    do_parse(params, fmtp)
  end

  defp do_parse([], fmtp), do: {:ok, fmtp}

  defp do_parse(params, fmtp) do
    case parse_param(params, fmtp) do
      {rest, %__MODULE__{} = fmtp} -> do_parse(rest, fmtp)
      {:error, _reason} = error -> error
    end
  end

  defp parse_param(["profile-level-id=" <> profile_level_id | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_hex_string(profile_level_id),
         do: {rest, %{fmtp | profile_level_id: value}}
  end

  defp parse_param(["level-asymmetry-allowed=" <> level_asymmetry_allowed | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_bool_string(level_asymmetry_allowed),
         do: {rest, %{fmtp | level_asymmetry_allowed: value}}
  end

  defp parse_param(["packetization-mode=" <> packetization_mode | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(packetization_mode),
         do: {rest, %{fmtp | packetization_mode: value}}
  end

  defp parse_param(["max-mbps=" <> max_mbps | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(max_mbps),
         do: {rest, %{fmtp | max_mbps: value}}
  end

  defp parse_param(["max-smbps=" <> max_smbps | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(max_smbps),
         do: {rest, %{fmtp | max_smbps: value}}
  end

  defp parse_param(["max-fs=" <> max_fs | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(max_fs), do: {rest, %{fmtp | max_fs: value}}
  end

  defp parse_param(["max-dpb=" <> max_dpb | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(max_dpb),
         do: {rest, %{fmtp | max_dpb: value}}
  end

  defp parse_param(["max-br=" <> max_br | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(max_br), do: {rest, %{fmtp | max_br: value}}
  end

  defp parse_param(["maxaveragebitrate=" <> maxaveragebitrate | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(maxaveragebitrate),
         do: {rest, %{fmtp | maxaveragebitrate: value}}
  end

  defp parse_param(["maxplaybackrate=" <> maxplaybackrate | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(maxplaybackrate),
         do: {rest, %{fmtp | maxplaybackrate: value}}
  end

  defp parse_param(["minptime=" <> minptime | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(minptime),
         do: {rest, %{fmtp | minptime: value}}
  end

  defp parse_param(["stereo=" <> stereo | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_bool_string(stereo),
         do: {rest, %{fmtp | stereo: value}}
  end

  defp parse_param(["cbr=" <> cbr | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_bool_string(cbr),
         do: {rest, %{fmtp | cbr: value}}
  end

  defp parse_param(["useinbandfec=" <> useinbandfec | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_bool_string(useinbandfec),
         do: {rest, %{fmtp | useinbandfec: value}}
  end

  defp parse_param(["usedtx=" <> usedtx | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_bool_string(usedtx),
         do: {rest, %{fmtp | usedtx: value}}
  end

  defp parse_param(["max-fr=" <> max_fr | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(max_fr),
         do: {rest, %{fmtp | max_fr: value}}
  end

  defp parse_param(["profile-id=" <> profile_id | rest], fmtp) do
    with {:ok, value} <- Utils.parse_numeric_string(profile_id),
         do: {rest, %{fmtp | profile_id: value}}
  end

  defp parse_param(["apt=" <> value | rest], fmtp), do: {rest, Map.put(fmtp, :apt, value)}

  defp parse_param(["repair-window=" <> value | rest], fmtp),
    do: {rest, Map.put(fmtp, :repair_window, value)}

  defp parse_param([head | rest], fmtp) do
    [start_range, end_range] = String.split(head, "-")

    with {:ok, start_range} <- Utils.parse_numeric_string(start_range),
         {:ok, end_range} <- Utils.parse_numeric_string(end_range) do
      {rest, Map.put(fmtp, :redundancy_range, "#{start_range}-#{end_range}")}
    else
      _ -> {:error, :unsupported_parameter}
    end
  end

  defp parse_param(_params, _fmtp), do: {:error, :unsupported_parameter}
end

defimpl String.Chars, for: ExSDP.Attribute.FMTP do
  def to_string(fmtp) do
    alias ExSDP.Serializer

    params =
      [
        # H264
        Serializer.maybe_serialize_hex("profile-level-id", fmtp.profile_level_id),
        Serializer.maybe_serialize("max-mbps", fmtp.max_mbps),
        Serializer.maybe_serialize("max-smbps", fmtp.max_smbps),
        Serializer.maybe_serialize("max-fs", fmtp.max_fs),
        Serializer.maybe_serialize("max-dpb", fmtp.max_dpb),
        Serializer.maybe_serialize("max-br", fmtp.max_br),
        Serializer.maybe_serialize("level-asymmetry-allowed", fmtp.level_asymmetry_allowed),
        Serializer.maybe_serialize("packetization-mode", fmtp.packetization_mode),
        # OPUS
        Serializer.maybe_serialize("maxaveragebitrate", fmtp.maxaveragebitrate),
        Serializer.maybe_serialize("maxplaybackrate", fmtp.maxplaybackrate),
        Serializer.maybe_serialize("minptime", fmtp.minptime),
        Serializer.maybe_serialize("stereo", fmtp.stereo),
        Serializer.maybe_serialize("cbr", fmtp.cbr),
        Serializer.maybe_serialize("useinbandfec", fmtp.useinbandfec),
        Serializer.maybe_serialize("usedtx", fmtp.usedtx),
        # VP8/9
        Serializer.maybe_serialize("profile-id", fmtp.profile_id),
        Serializer.maybe_serialize("max-fr", fmtp.max_fr)
      ]
      |> Enum.filter(fn param -> param != "" end)
      |> Enum.join(";")

    "fmtp:#{fmtp.pt} #{params}"
  end
end

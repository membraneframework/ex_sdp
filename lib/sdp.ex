defmodule Membrane.Protocol.SDP do
  @moduledoc """
  This module is responsible for parsing SDP multimedia session.
  """
  require Logger

  alias Membrane.Protocol.SDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    RepeatTimes,
    Session,
    Timezone,
    Timing
  }

  @line_ending ["\r\n", "\r", "\n"]
  @preffered_ending "\r\n"

  @doc """
  Parses SDP Multimedia Session.
  """
  @spec parse(binary()) ::
          {:ok, Session.t()} | {:error, atom() | {:not_supported_addr_type, binary()}}
  def parse(binary) do
    binary
    |> String.split(@line_ending)
    |> do_parse()
  end

  defp do_parse(lines, session \\ struct(Session))
  defp do_parse([""], session), do: {:ok, flip_media(session)}

  defp do_parse(lines, session) do
    with {rest, %Session{} = session} <- parse_line(lines, session) do
      do_parse(rest, session)
    else
      {:error, reason} ->
        {:error, {reason, List.first(lines)}}
    end
  end

  @doc """
  Parses SDP Multimedia Session raising an exception in case of failure.
  """
  @spec parse!(binary()) :: Session.t()
  def parse!(binary) do
    binary
    |> String.split(@line_ending)
    |> do_parse!()
  end

  defp do_parse!(lines, session \\ struct(Session))
  defp do_parse!([""], session), do: flip_media(session)

  defp do_parse!(lines, session) do
    case parse_line(lines, session) do
      {:error, reason} ->
        error_message = format_error(lines, reason)
        raise error_message

      {rest, %Session{} = session} ->
        do_parse!(rest, session)
    end
  end

  @doc """
  Serializes SDP.Session struct into SDP Multimedia Session string.
  """
  @spec serialize(Session.t()) :: binary()
  def serialize(session) do
    session_fields_serialized = [
      serialize_version(session.version),
      Origin.serialize(session.origin),
      serialize_session_name(session.session_name),
      serialize_session_information(session.session_information),
      serialize_uri(session.uri),
      serialize_email(session.email),
      serialize_phone_number(session.phone_number),
      Enum.map_join(session.connection_data, @preffered_ending, &ConnectionData.serialize/1),
      Enum.map_join(session.bandwidth, @preffered_ending, &Bandwidth.serialize/1),
      Timing.serialize(session.timing),
      Enum.map_join(session.time_repeats, @preffered_ending, &RepeatTimes.serialize/1),
      Enum.map_join(session.time_zones_adjustments, @preffered_ending, &Timezone.serialize/1),
      Encryption.serialize(session.encryption),
      Enum.map_join(session.attributes, @preffered_ending, &Attribute.serialize/1),
      Enum.map_join(session.media, @preffered_ending, &Media.serialize/1)
    ]

    session_fields_serialized |> Enum.reject(&(&1 == "")) |> Enum.join(@preffered_ending)
  end

  defp parse_line(lines, session)

  defp parse_line(["v=" <> version | rest], spec),
    do: {rest, %Session{spec | version: version}}

  defp parse_line(["o=" <> origin | rest], spec) do
    with {:ok, %Origin{} = origin} <- Origin.parse(origin) do
      {rest, %Session{spec | origin: origin}}
    end
  end

  defp parse_line(["s=" <> session_name | rest], spec),
    do: {rest, %Session{spec | session_name: session_name}}

  defp parse_line(["i=" <> session_information | rest], spec),
    do: {rest, %Session{spec | session_information: session_information}}

  defp parse_line(["u=" <> uri | rest], spec),
    do: {rest, %Session{spec | uri: uri}}

  defp parse_line(["e=" <> email | rest], spec),
    do: {rest, %Session{spec | email: email}}

  defp parse_line(["p=" <> phone_number | rest], spec),
    do: {rest, %Session{spec | phone_number: phone_number}}

  defp parse_line(["c=" <> connection_data | rest], spec) do
    with {:ok, connection_info} <- ConnectionData.parse(connection_data) do
      {rest, %Session{spec | connection_data: connection_info}}
    end
  end

  defp parse_line(["b=" <> bandwidth | rest], %Session{bandwidth: acc_bandwidth} = spec) do
    with {:ok, bandwidth} <- Bandwidth.parse(bandwidth) do
      {rest, %Session{spec | bandwidth: [bandwidth | acc_bandwidth]}}
    end
  end

  defp parse_line(["t=" <> timing | rest], spec) do
    with {:ok, timing} <- Timing.parse(timing) do
      {rest, %Session{spec | timing: timing}}
    end
  end

  defp parse_line(["r=" <> repeat | rest], %Session{time_repeats: time_repeats} = spec) do
    with {:ok, repeats} <- RepeatTimes.parse(repeat) do
      {rest, %Session{spec | time_repeats: [repeats | time_repeats]}}
    end
  end

  defp parse_line(["z=" <> timezones | rest], spec) do
    with {:ok, timezones} <- Timezone.parse(timezones) do
      {rest, %Session{spec | time_zones_adjustments: timezones}}
    end
  end

  defp parse_line(["k=" <> encryption | rest], spec) do
    with {:ok, encryption} <- Encryption.parse(encryption) do
      {rest, %Session{spec | encryption: encryption}}
    end
  end

  defp parse_line(["a=" <> attribute | rest], %{attributes: attrs} = session) do
    with {:ok, attribute} <- Attribute.parse(attribute) do
      {rest, %Session{session | attributes: [attribute | attrs]}}
    end
  end

  defp parse_line(["m=" <> medium | rest], %Session{media: media} = session) do
    with {:ok, medium} <- Media.parse(medium),
         {:ok, {rest, medium}} <- Media.parse_optional(rest, medium) do
      medium = Media.apply_session(medium, session)
      {rest, %Session{session | media: [medium | media]}}
    end
  end

  defp format_error(["m=" <> _ = line | rest], reason) do
    attributes =
      rest
      |> Enum.take_while(fn
        "" -> false
        line -> not String.starts_with?(line, "m=")
      end)
      |> Enum.join("\n")

    """
    Error while parsing media:
    #{line}

    Attributes:
    #{attributes}

    with reason: #{reason}
    """
  end

  defp format_error([line | _], reason) do
    """
    An error has occurred while parsing following SDP line:
    #{line}
    with reason: #{reason}
    """
  end

  defp flip_media(%{media: media} = session),
    do: %{session | media: Enum.reverse(media)}

  defp serialize_version(version), do: "v=" <> Integer.to_string(version)

  defp serialize_session_name(session_name), do: "s=" <> session_name

  defp serialize_session_information(nil), do: ""
  defp serialize_session_information(session_information), do: "i=" <> session_information

  defp serialize_uri(nil), do: ""
  defp serialize_uri(uri), do: "u=" <> uri

  defp serialize_email(nil), do: ""
  defp serialize_email(email), do: "e=" <> email

  defp serialize_phone_number(nil), do: ""
  defp serialize_phone_number(number), do: "p=" <> number
end

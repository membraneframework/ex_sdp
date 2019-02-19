defmodule Membrane.Protocol.SDP do
  use Bunch
  require Logger

  @moduledoc """

   The set of type letters is deliberately small and not intended to be
   extensible -- an SDP parser MUST completely ignore any session
   description that contains a type letter that it does not understand.
  """
  alias Membrane.Protocol.SDP.{
    ConnectionInformation,
    Bandwidth,
    Encryption,
    Media,
    Origin,
    Session,
    Timezone,
    Timing,
    RepeatTimes
  }

  @spec parse(binary()) ::
          {:error,
           :duration_nan
           | :einval
           | :interval_nan
           | :invalid_bandwidth
           | :invalid_connection_information
           | :invalid_media_spec
           | :invalid_origin
           | :invalid_repeat
           | :invalid_timezone
           | :invalid_timing
           | :malformed_port_number
           | :offset_nan
           | {:not_supported_addr_type, binary()}}
          | Membrane.Protocol.SDP.Session.t()
  def parse(binary) do
    binary
    |> String.split("\r\n")
    |> do_parse()
  end

  defp do_parse(lines, spec \\ %Session{})
  defp do_parse([""], spec), do: spec

  defp do_parse(lines, spec) do
    case parse_line(lines, spec) do
      {:error, cause} = error ->
        report_error(lines, cause)
        error

      {rest, %Session{} = session} ->
        do_parse(rest, session)
    end
  end

  defp parse_line(lines, session)

  defp parse_line(["v=" <> version | rest], spec),
    do: %Session{spec | version: version} ~> {rest, &1}

  defp parse_line(["o=" <> origin | rest], spec) do
    origin
    |> Origin.parse()
    ~>> ({:ok, origin} -> %Session{spec | origin: origin} ~> {rest, &1})
  end

  defp parse_line(["s=" <> session_name | rest], spec),
    do: %Session{spec | session_name: session_name} ~> {rest, &1}

  defp parse_line(["i=" <> session_information | rest], spec),
    do: %Session{spec | session_information: session_information} ~> {rest, &1}

  defp parse_line(["u=" <> uri | rest], spec),
    do: %Session{spec | uri: uri} ~> {rest, &1}

  defp parse_line(["e=" <> email | rest], spec),
    do: %Session{spec | email: email} ~> {rest, &1}

  defp parse_line(["p=" <> phone_number | rest], spec),
    do: %Session{spec | phone_number: phone_number} ~> {rest, &1}

  defp parse_line(["c=" <> connection_data | rest], spec) do
    connection_data
    |> ConnectionInformation.parse()
    ~>> ({:ok, connection_info} -> %Session{spec | connection: connection_info} ~> {rest, &1})
  end

  defp parse_line(["b=" <> bandwidth | rest], spec) do
    bandwidth
    |> Bandwidth.parse()
    ~>> ({:ok, bandwidth} -> %Session{spec | bandwidth: bandwidth} ~> {rest, &1})
  end

  defp parse_line(["t=" <> timing | rest], spec) do
    timing
    |> Timing.parse()
    ~>> ({:ok, timing} -> %Session{spec | timing: timing} ~> {rest, &1})
  end

  defp parse_line(["r=" <> repeat | rest], spec) do
    repeat
    |> RepeatTimes.parse()
    ~>> ({:ok, repeats} -> %Session{spec | time_repeats: repeats} ~> {rest, &1})
  end

  defp parse_line(["z=" <> timezones | rest], spec) do
    timezones
    |> Timezone.parse()
    ~>> ({:ok, timezones} -> %Session{spec | time_zones_adjustments: timezones} ~> {rest, &1})
  end

  defp parse_line(["k=" <> encryption | rest], spec) do
    encryption
    |> Encryption.parse()
    ~> %Session{spec | encryption: encryption}
    ~> {rest, &1}
  end

  defp parse_line(["a=" <> attribute | rest], %Session{attributes: attrs} = session) do
    case String.split(attribute, ":", parts: 2) do
      [name, value] ->
        name = String.replace(name, "-", "-")

        {name, value}

      [flag] ->
        flag
    end
    ~> %Session{session | attributes: [&1 | attrs]}
    ~> {rest, &1}
  end

  defp parse_line(["m=" <> media | rest], %Session{medias: medias} = session) do
    with {:ok, media} <- Media.parse(media),
         {:ok, {rest, media}} <- Media.parse_optional(rest, media) do
      %Session{session | medias: [media | medias]}
      ~> {rest, &1}
    end
  end

  defp report_error(["m=" <> _ = line | rest], cause) do
    attributes =
      Enum.take_while(rest, fn
        "" -> false
        line -> String.starts_with?(line, "m=")
      end)

    Logger.error("""
    Error whil parsing media:
    #{line}

    Attributes:
    #{attributes}

    Caused by: #{cause}
    """)
  end

  defp report_error([line | _], cause) do
    Logger.error("""
    An error has occurred while parsing following SDP line:
    #{line}
    with cause: #{cause}
    """)
  end
end

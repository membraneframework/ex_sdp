defmodule ExSDP.Parser do
  @moduledoc """
  This module is responsible for parsing SDP multimedia session.
  """
  use Bunch.Access

  require Logger

  alias ExSDP

  alias ExSDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    RepeatTimes,
    Timezone,
    Timing
  }

  @line_ending ["\r\n", "\r", "\n"]

  @typedoc """
  Options of the parser:
  * `:lenient` - when `true`, a line, section or an attribute that cannot be parsed is
    logged and skipped or kept unparsed instead of failing the whole description.
    Defaults to `false`.
  """
  @type parse_opts :: [lenient: boolean()]

  @doc """
  Parses SDP Multimedia Session.

  See `t:parse_opts/0` for the options.
  """
  @spec parse(binary(), parse_opts()) ::
          {:ok, ExSDP.t()} | {:error, atom() | {:not_supported_addr_type, binary()}}
  def parse(binary, opts \\ []) do
    binary
    |> String.split(@line_ending)
    |> do_parse(struct(ExSDP), opts)
  end

  defp do_parse(lines, session, _opts) when lines in [[""], []],
    do: {:ok, flip_media(session)}

  defp do_parse(lines, session, opts) do
    lenient? = Keyword.get(opts, :lenient, false)

    case parse_line(lines, session, opts) do
      {rest, %ExSDP{} = session} ->
        do_parse(rest, session, opts)

      {:error, reason} when lenient? ->
        lines |> skip_line(reason) |> do_parse(session, opts)

      {:error, reason} ->
        {:error, {reason, List.first(lines)}}
    end
  end

  @doc """
  Parses SDP Multimedia Session raising an exception in case of failure.

  See `t:parse_opts/0` for the options.
  """
  @spec parse!(binary(), parse_opts()) :: ExSDP.t()
  def parse!(binary, opts \\ []) do
    binary
    |> String.split(@line_ending)
    |> do_parse!(struct(ExSDP), opts)
  end

  defp do_parse!(lines, session, _opts) when lines in [[""], []], do: flip_media(session)

  defp do_parse!(lines, session, opts) do
    lenient? = Keyword.get(opts, :lenient, false)

    case parse_line(lines, session, opts) do
      {rest, %ExSDP{} = session} ->
        do_parse!(rest, session, opts)

      {:error, reason} when lenient? ->
        lines |> skip_line(reason) |> do_parse!(session, opts)

      {:error, reason} ->
        error_message = format_error(lines, reason)
        raise error_message
    end
  end

  # A media line that cannot be parsed takes its section with it: the lines that
  # follow describe that media and must not be attached to anything else.
  defp skip_line(["m=" <> _medium = line | rest], reason) do
    Logger.warning("Ignoring SDP media section #{inspect(line)}: #{inspect(reason)}")
    Enum.drop_while(rest, &(not String.starts_with?(&1, "m=")))
  end

  defp skip_line([line | rest], reason) do
    Logger.warning("Ignoring SDP line #{inspect(line)}: #{inspect(reason)}")
    rest
  end

  defp parse_line(lines, session, opts)

  defp parse_line(["a=" <> attribute | rest], %ExSDP{attributes: attrs} = session, opts) do
    with {:ok, attribute} <- Attribute.parse(attribute, Keyword.take(opts, [:lenient])) do
      {rest, %ExSDP{session | attributes: [attribute | attrs]}}
    end
  end

  defp parse_line(["m=" <> medium | rest], %ExSDP{media: media} = session, opts) do
    with {:ok, medium} <- Media.parse(medium, opts),
         {:ok, {rest, medium}} <- Media.parse_optional(rest, medium, opts) do
      medium = Media.apply_session(medium, session)
      {rest, %ExSDP{session | media: [medium | media]}}
    end
  end

  defp parse_line(["" | rest], session, _opts), do: {rest, session}

  defp parse_line(lines, session, _opts), do: parse_line(lines, session)

  defp parse_line(lines, session)

  defp parse_line(["v=" <> version | rest], %ExSDP{} = spec) do
    case version |> String.trim() |> Integer.parse() do
      {version, ""} -> {rest, %ExSDP{spec | version: version}}
      _other -> {:error, :invalid_version}
    end
  end

  defp parse_line(["o=" <> origin | rest], %ExSDP{} = spec) do
    with {:ok, %Origin{} = origin} <- Origin.parse(origin) do
      {rest, %ExSDP{spec | origin: origin}}
    end
  end

  defp parse_line(["s=" <> session_name | rest], %ExSDP{} = spec),
    do: {rest, %ExSDP{spec | session_name: session_name}}

  defp parse_line(["i=" <> session_information | rest], %ExSDP{} = spec),
    do: {rest, %ExSDP{spec | session_information: session_information}}

  defp parse_line(["u=" <> uri | rest], %ExSDP{} = spec),
    do: {rest, %ExSDP{spec | uri: uri}}

  defp parse_line(["e=" <> email | rest], %ExSDP{} = spec),
    do: {rest, %ExSDP{spec | email: email}}

  defp parse_line(["p=" <> phone_number | rest], %ExSDP{} = spec),
    do: {rest, %ExSDP{spec | phone_number: phone_number}}

  defp parse_line(["c=" <> connection_data | rest], %ExSDP{} = spec) do
    with {:ok, %ConnectionData{} = connection_data} <- ConnectionData.parse(connection_data) do
      {rest, %ExSDP{spec | connection_data: connection_data}}
    end
  end

  defp parse_line(["b=" <> bandwidth | rest], %ExSDP{bandwidth: acc_bandwidth} = spec) do
    with {:ok, bandwidth} <- Bandwidth.parse(bandwidth) do
      {rest, %ExSDP{spec | bandwidth: [bandwidth | acc_bandwidth]}}
    end
  end

  defp parse_line(["t=" <> timing | rest], %ExSDP{} = spec) do
    with {:ok, timing} <- Timing.parse(timing) do
      {rest, %ExSDP{spec | timing: timing}}
    end
  end

  defp parse_line(["r=" <> repeat | rest], %ExSDP{time_repeats: time_repeats} = spec) do
    with {:ok, repeats} <- RepeatTimes.parse(repeat) do
      {rest, %ExSDP{spec | time_repeats: [repeats | time_repeats]}}
    end
  end

  defp parse_line(["z=" <> timezones | rest], %ExSDP{} = spec) do
    with {:ok, timezones} <- Timezone.parse(timezones) do
      {rest, %ExSDP{spec | time_zones_adjustments: timezones}}
    end
  end

  defp parse_line(["k=" <> encryption | rest], %ExSDP{} = spec) do
    with {:ok, encryption} <- Encryption.parse(encryption) do
      {rest, %ExSDP{spec | encryption: encryption}}
    end
  end

  defp parse_line(_lines, _session), do: {:error, :invalid_line}

  defp format_error(["m=" <> _rest = line | rest], reason) do
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

  defp format_error([line | _rest], reason) do
    """
    An error has occurred while parsing following SDP line:
    #{line}
    with reason: #{reason}
    """
  end

  defp flip_media(%{media: media} = session),
    do: %{session | media: Enum.reverse(media)}
end

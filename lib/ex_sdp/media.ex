defmodule ExSDP.Media do
  @moduledoc """
  This module represents the Media field of SDP.

  For more details please see [RFC4566 Section 5.14](https://tools.ietf.org/html/rfc4566#section-5.14)
  """
  use Bunch
  use Bunch.Access

  require Logger

  alias ExSDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Utils
  }

  @enforce_keys [:type, :port, :protocol, :fmt]
  defstruct @enforce_keys ++
              [
                :title,
                :encryption,
                port_count: 1,
                connection_data: [],
                bandwidth: [],
                attributes: []
              ]

  @type t :: %__MODULE__{
          type: type(),
          port: :inet.port_number(),
          port_count: non_neg_integer(),
          protocol: binary(),
          fmt: binary() | [0..127],
          title: binary() | nil,
          connection_data: [ConnectionData.t()],
          bandwidth: [Bandwidth.t()],
          encryption: Encryption.t() | nil,
          attributes: [Attribute.t()]
        }

  @typedoc """
  Represents type of media. In [RFC4566](https://tools.ietf.org/html/rfc4566#section-5.14)
  there are defined "audio", "video", "text", "application", and "message" types.

  Known types are represented as atoms others are binaries.
  """
  @type type :: :audio | :video | :text | :application | :message | binary()

  @spec new(type(), :inet.port_number(), binary(), binary() | 0..127 | [0..127],
          port_count: non_neg_integer()
        ) :: t()
  def new(type, port, protocol, fmt, opts \\ []) do
    %__MODULE__{
      type: type,
      port: port,
      port_count: opts[:port_count] || 1,
      protocol: protocol,
      fmt: Bunch.listify(fmt)
    }
  end

  @deprecated "Use ExSDP.add_attribute/2 instead"
  @spec add_attribute(t(), Attribute.t()) :: t()
  def add_attribute(media, attribute), do: add_attributes(media, [attribute])

  @deprecated "Use ExSDP.add_attributes/2 instead"
  @spec add_attributes(t(), [Attribute.t()]) :: t()
  def add_attributes(media, attributes) when is_list(attributes),
    do: Map.update!(media, :attributes, &(&1 ++ attributes))

  @deprecated "Use ExSDP.get_attribute/2 instead"
  @spec get_attribute(t(), Attribute.key()) :: Attribute.t() | nil
  def get_attribute(media, key), do: Utils.get_attribute(media, key)

  @deprecated "Use ExSDP.get_attributes/2 instead"
  @spec get_attributes(t(), Attribute.key()) :: [Attribute.t()]
  def get_attributes(media, key), do: Utils.get_attributes(media, key)

  @spec parse(binary(), ExSDP.Parser.parse_opts()) ::
          {:ok, t()} | {:error, :invalid_media_spec | :malformed_port_number}
  def parse(media, opts \\ []) do
    withl conn: [type, port, proto, fmt] <- String.split(media, " ", parts: 4),
          port: {port, port_count} when port in 0..65_535 <- Integer.parse(port),
          port_count:
            port_count when is_integer(port_count) and port_count > 0 <-
              parse_port_count(port_count),
          fmt: {:ok, fmt} <- parse_fmt(fmt, proto, opts) do
      media = %__MODULE__{
        type: parse_type(type),
        port: port,
        port_count: port_count,
        protocol: proto,
        fmt: fmt
      }

      {:ok, media}
    else
      conn: _error -> {:error, :invalid_media_spec}
      port: _error -> {:error, :invalid_port_number}
      port_count: _error -> {:error, :invalid_port_count}
      fmt: error -> error
    end
  end

  @spec parse_optional([binary()], t(), ExSDP.Parser.parse_opts()) ::
          {:ok, {[binary()], t()}} | {:error, atom()}
  def parse_optional(lines, %__MODULE__{} = media, opts \\ []) do
    lenient? = Keyword.get(opts, :lenient, false)
    {media_lines, rest} = Enum.split_while(lines, fn line -> not match?("m=" <> _media, line) end)

    result =
      media_lines
      |> Enum.reject(fn line -> line == "" end)
      |> Enum.reduce_while({:ok, media}, fn line, {:ok, media} ->
        case parse_optional_line(line, media, opts) do
          {:ok, %__MODULE__{} = media} ->
            {:cont, {:ok, media}}

          {:error, reason} when lenient? ->
            Logger.warning("Ignoring SDP line #{inspect(line)}: #{inspect(reason)}")
            {:cont, {:ok, media}}

          {:error, reason} ->
            {:halt, {:error, reason}}
        end
      end)

    with {:ok, media} <- result do
      rest = if rest == [], do: [""], else: rest
      {:ok, {rest, finalize_optional_parsing(media)}}
    end
  end

  defp parse_optional_line("i=" <> title, %__MODULE__{} = media, _opts),
    do: {:ok, %__MODULE__{media | title: title}}

  defp parse_optional_line("c=" <> conn, %__MODULE__{} = media, _opts) do
    with {:ok, %ConnectionData{} = connection_data} <- ConnectionData.parse(conn) do
      {:ok, %__MODULE__{media | connection_data: media.connection_data ++ [connection_data]}}
    end
  end

  defp parse_optional_line(
         "b=" <> bandwidth,
         %__MODULE__{bandwidth: acc_bandwidth} = media,
         _opts
       ) do
    with {:ok, bandwidth} <- Bandwidth.parse(bandwidth) do
      {:ok, %__MODULE__{media | bandwidth: [bandwidth | acc_bandwidth]}}
    end
  end

  defp parse_optional_line("k=" <> encryption, %__MODULE__{} = media, _opts) do
    with {:ok, encryption} <- Encryption.parse(encryption) do
      {:ok, %__MODULE__{media | encryption: encryption}}
    end
  end

  defp parse_optional_line("a=" <> attribute, %__MODULE__{attributes: attrs} = media, opts) do
    opts = [media_type: media.type] ++ Keyword.take(opts, [:lenient])

    with {:ok, attribute} <- Attribute.parse(attribute, opts) do
      {:ok, %__MODULE__{media | attributes: [attribute | attrs]}}
    end
  end

  defp parse_optional_line(_line, _media, _opts), do: {:error, :invalid_line}

  @spec apply_session(__MODULE__.t(), ExSDP.t()) :: __MODULE__.t()
  def apply_session(media, session) do
    session
    |> Map.from_struct()
    |> Enum.reduce(Map.from_struct(media), fn
      {inherited_key, value}, acc
      when inherited_key == :encryption ->
        if acc[inherited_key] != nil,
          do: acc,
          else: Map.put(acc, inherited_key, value)

      {inherited_key, value}, acc when inherited_key in [:connection_data, :bandwidth] ->
        if acc[inherited_key] != [],
          do: acc,
          else: Map.put(acc, inherited_key, value)

      _key_value, acc ->
        acc
    end)
    ~> struct(__MODULE__, &1)
  end

  defp finalize_optional_parsing(%__MODULE__{attributes: attrs} = media) do
    %__MODULE__{media | attributes: Enum.reverse(attrs)}
  end

  defp parse_type(type) when type in ["audio", "video", "text", "application", "message"],
    do: String.to_atom(type)

  defp parse_type(type) when is_binary(type), do: type

  @rtp_protocols [
    "RTP/AVP",
    "RTP/AVP/TCP",
    "RTP/AVPF",
    "RTP/SAVP",
    "RTP/SAVPF",
    "UDP/TLS/RTP/SAVP",
    "UDP/TLS/RTP/SAVPF"
  ]

  defp parse_fmt(fmt, proto, opts) when proto in @rtp_protocols do
    parsed = fmt |> String.split() |> Enum.map(&Integer.parse/1)

    cond do
      Enum.all?(parsed, &match?({_payload_type, ""}, &1)) ->
        {:ok, Enum.map(parsed, fn {payload_type, ""} -> payload_type end)}

      # for backward compatibility, invalid formats of RTP/AVP/TCP are never an error
      Keyword.get(opts, :lenient, false) or proto == "RTP/AVP/TCP" ->
        Logger.warning(
          "SDP media formats #{inspect(fmt)} are not RTP payload types, keeping them as they are"
        )

        {:ok, fmt}

      true ->
        {:error, :invalid_fmt}
    end
  end

  defp parse_fmt(fmt, _proto, _opts), do: {:ok, fmt}

  defp parse_port_count(""), do: 1

  defp parse_port_count("/" <> port_count) do
    case Integer.parse(port_count) do
      {port_count, ""} -> port_count
      _not_matched -> :error
    end
  end

  defp parse_port_count(_not_a_port_count), do: :error
end

defimpl String.Chars, for: ExSDP.Media do
  @impl true
  def to_string(media) do
    import ExSDP.Sigil

    serialized_header = media |> header_fields |> String.trim()

    ~n"""
    #{serialized_header}
    #{ExSDP.Serializer.maybe_serialize("i", media.title)}
    #{ExSDP.Serializer.maybe_serialize("c", media.connection_data)}
    #{ExSDP.Serializer.maybe_serialize("b", media.bandwidth)}
    #{ExSDP.Serializer.maybe_serialize("k", media.encryption)}
    #{ExSDP.Serializer.maybe_serialize("a", media.attributes)}
    """
    # to_string has to return string without `\r\n` at the end
    |> String.trim()
  end

  defp header_fields(media) do
    """
    #{media.type} \
    #{serialize_port(media.port, media.port_count)} \
    #{media.protocol} \
    #{serialize_fmt(media.fmt)} \
    """
  end

  defp serialize_port(port, 1), do: "#{port}"
  defp serialize_port(port, port_count), do: "#{port}/#{port_count}"

  defp serialize_fmt(fmt) when is_binary(fmt), do: fmt
  defp serialize_fmt(fmt), do: Enum.map_join(fmt, " ", &Kernel.to_string/1)
end

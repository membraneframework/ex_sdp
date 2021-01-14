defmodule ExSDP.Media do
  @moduledoc """
  This module represents the Media field of SDP.

  For more details please see [RFC4566 Section 5.14](https://tools.ietf.org/html/rfc4566#section-5.14)
  """
  use Bunch
  @enforce_keys [:type, :ports, :protocol, :fmt]
  defstruct @enforce_keys ++
              [
                :title,
                :encryption,
                connection_data: [],
                bandwidth: [],
                attributes: []
              ]

  alias ExSDP

  alias ExSDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption
  }

  @typedoc """
  Represents type of media. In [RFC4566](https://tools.ietf.org/html/rfc4566#section-5.14)
  there are defined "audio", "video", "text", "application", and "message" types.

  Known types are represented as atoms others are binaries.
  """
  @type type :: :audio | :video | :text | :application | :message | binary()

  @type t :: %__MODULE__{
          type: type(),
          ports: [:inet.port_number()],
          protocol: binary(),
          fmt: binary() | [0..127],
          title: binary() | nil,
          connection_data: ConnectionData.t(),
          bandwidth: [Bandwidth.t()],
          encryption: Encryption.t() | nil,
          attributes: [binary()]
        }

  @spec new(
          type :: type(),
          ports :: [:inet.port_number()],
          protocol :: binary(),
          fmt :: binary() | [0..127]
        ) :: t()
  def new(type, ports, protocol, fmt) do
    %__MODULE__{
      type: type,
      ports: ports,
      protocol: protocol,
      fmt: fmt
    }
  end

  @spec set_connection_data(media :: t(), connection_data :: ConnectionData.t()) :: t()
  def set_connection_data(media, connection_data) do
    Bunch.Struct.put_in(media, :connection_data, connection_data)
  end

  @spec add_attribute(media :: t(), attribute :: Attribute.t()) :: t()
  def add_attribute(media, attribute) do
    attributes = media.attributes ++ [attribute]
    Bunch.Struct.put_in(media, :attributes, attributes)
  end

  @spec get_attribute(media :: t(), key :: String.t()) :: Attribute.t()
  def get_attribute(media, key) do
    media.attributes
    |> Enum.find(fn {k, _v} -> k == key end)
  end

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_media_spec | :malformed_port_number}
  def parse(media) do
    withl conn: [type, port, proto, fmt] <- String.split(media, " ", parts: 4),
          int: {port_no, port_options} when port_no in 0..65_535 <- Integer.parse(port),
          fmt: {:ok, fmt} <- parse_fmt(fmt, proto) do
      media = %__MODULE__{
        type: parse_type(type),
        ports: gen_ports(port_no, port_options),
        protocol: proto,
        fmt: fmt
      }

      {:ok, media}
    else
      conn: _ -> {:error, :invalid_media_spec}
      int: _ -> {:error, :malformed_port_number}
      fmt: error -> error
    end
  end

  @spec parse_optional([binary()], t()) :: {:ok, {[binary()], t()}} | {:error, atom()}
  def parse_optional(lines, media)

  def parse_optional([""], media), do: {:ok, {[""], finalize_optional_parsing(media)}}

  def parse_optional(["m=" <> _ | _] = lines, media),
    do: {:ok, {lines, finalize_optional_parsing(media)}}

  def parse_optional(["i=" <> title | rest], media),
    do: parse_optional(rest, %__MODULE__{media | title: title})

  def parse_optional(["c=" <> conn | rest], %__MODULE__{connection_data: info} = media) do
    with {:ok, conn} <- ConnectionData.parse(conn) do
      conn
      |> Bunch.listify()
      ~> %__MODULE__{media | connection_data: %ConnectionData{addresses: &1 ++ info}}
      ~> parse_optional(rest, &1)
    end
  end

  def parse_optional(["b=" <> bandwidth | rest], %__MODULE__{bandwidth: acc_bandwidth} = media) do
    with {:ok, bandwidth} <- Bandwidth.parse(bandwidth) do
      bandwidth = %__MODULE__{media | bandwidth: [bandwidth | acc_bandwidth]}
      parse_optional(rest, bandwidth)
    end
  end

  def parse_optional(["k=" <> encryption | rest], media) do
    with {:ok, encryption} <- Encryption.parse(encryption) do
      encryption = %__MODULE__{media | encryption: encryption}
      parse_optional(rest, encryption)
    end
  end

  def parse_optional(["a=" <> attribute | rest], %__MODULE__{attributes: attrs} = media) do
    with {:ok, attribute} <- Attribute.parse(attribute, media_type: media.type) do
      media = %__MODULE__{media | attributes: [attribute | attrs]}
      parse_optional(rest, media)
    end
  end

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

      _, acc ->
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

  defp parse_fmt(fmt, proto) when proto == "RTP/AVP" or proto == "RTP/SAVP" do
    fmt
    |> String.split(" ")
    |> Bunch.Enum.try_map(fn single_fmt ->
      case Integer.parse(single_fmt) do
        {parsed_fmt, ""} -> {:ok, parsed_fmt}
        _ -> {:error, :invalid_fmt}
      end
    end)
  end

  defp parse_fmt(fmt, _), do: {:ok, fmt}

  defp gen_ports(port_no, "/" <> port_count) do
    port_count
    |> Integer.parse()
    |> case do
      {port_count, ""} ->
        port_no
        |> Stream.unfold(fn port_no -> {port_no, port_no + 2} end)
        |> Stream.take(port_count)
        |> Enum.into([])

      _ ->
        {:error, :invalid_port_count}
    end
  end

  defp gen_ports(port_no, _), do: [port_no]
end

defimpl String.Chars, for: ExSDP.Media do
  def to_string(media) do
    import ExSDP.Sigil

    serialized_header = media |> header_fields |> String.trim()

    ~n"""
    #{serialized_header}
    #{ExSDP.Serializer.maybe_serialize("i", Map.get(media, :title))}
    #{ExSDP.Serializer.maybe_serialize("c", Map.get(media, :connection_data))}
    #{ExSDP.Serializer.maybe_serialize("b", Map.get(media, :bandwidth))}
    #{ExSDP.Serializer.maybe_serialize("k", Map.get(media, :encryption))}
    #{ExSDP.Serializer.maybe_serialize("a", Map.get(media, :attributes))}
    """
    # to_string has to return string without `\r\n` at the end
    |> String.trim()
  end

  defp header_fields(media) do
    """
    #{serialize_type(media.type)} \
    #{serialize_ports(media.ports)} \
    #{media.protocol} \
    #{serialize_fmt(media.fmt)} \
    """
  end

  defp serialize_type(type), do: "#{type}"

  defp serialize_ports([port]), do: "#{port}"

  defp serialize_ports([port | _rest] = ports), do: "#{port}/#{length(ports)}"

  defp serialize_fmt(fmt) when is_binary(fmt), do: fmt
  defp serialize_fmt(fmt), do: Enum.map_join(fmt, " ", &Kernel.to_string/1)
end

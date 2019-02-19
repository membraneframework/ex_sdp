defmodule Membrane.Protocol.SDP.Media do
  use Bunch
  @enforce_keys [:type, :port, :protocol, :fmt]
  defstruct @enforce_keys ++
              [
                # optional - represented by i
                :title,
                # optional - represented by c
                :connection_information,
                # optional - represented by b
                :bandwidth,
                # optional - represented by k
                :encryption,
                # optional - represented by a
                {:attributes, []}
              ]

  alias Membrane.Protocol.SDP.{Encryption, Bandwidth, ConnectionInformation}

  @type t :: %__MODULE__{
          type: binary(),
          port: :inet.port_number(),
          protocol: binary(),
          fmt: binary(),
          title: binary() | nil,
          connection_information: ConnectionInformation.t() | nil,
          bandwidth: Bandwidth.t() | nil,
          encryption: Encryption.t() | nil,
          attributes: [binary()]
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_media_spec | :malformed_port_number}
  def parse(media) do
    withl conn: [type, port, proto, fmt] <- String.split(media, " ", parts: 4),
          int: {port_no, ""} when port_no in 0..65535 <- Integer.parse(port) do
      %__MODULE__{
        type: type,
        port: port_no,
        protocol: proto,
        fmt: fmt
      }
      ~> {:ok, &1}
    else
      conn: _ -> {:error, :invalid_media_spec}
      int: _ -> {:error, :malformed_port_number}
    end
  end

  @spec parse_optional([binary()], t()) :: {:ok, {[binary()], t()}} | {:error, atom()}
  def parse_optional(lines, media)

  def parse_optional([""], media), do: {[""], finalize_optional_parsing(media)} ~> {:ok, &1}

  def parse_optional(["m=" <> _ | _] = lines, media),
    do: {lines, finalize_optional_parsing(media)} ~> {:ok, &1}

  def parse_optional(["i=" <> title | rest], media),
    do: parse_optional(rest, %__MODULE__{media | title: title})

  def parse_optional(["c=" <> conn | rest], media) do
    conn
    |> ConnectionInformation.parse()
    ~>> ({:ok, conn} ->
           %__MODULE__{media | connection_information: conn}
           ~> parse_optional(rest, &1))
  end

  def parse_optional(["b=" <> bandwidth | rest], media) do
    bandwidth
    |> Bandwidth.parse()
    ~>> ({:ok, bandwidth} ->
           %__MODULE__{media | bandwidth: bandwidth} ~> parse_optional(rest, &1))
  end

  def parse_optional(["k=" <> encryption | rest], media) do
    encryption
    |> Encryption.parse()
    ~> %__MODULE__{media | encryption: &1}
    ~> parse_optional(rest, &1)
  end

  def parse_optional(["a=" <> attribute | rest], %__MODULE__{attributes: attrs} = media) do
    %__MODULE__{media | attributes: [attribute | attrs]}
    ~> parse_optional(rest, &1)
  end

  defp finalize_optional_parsing(%__MODULE__{attributes: attrs} = media) do
    attrs
    |> Enum.reverse()
    ~> %__MODULE__{media | attributes: &1}
  end
end

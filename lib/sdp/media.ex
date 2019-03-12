defmodule Membrane.Protocol.SDP.Media do
  @moduledoc """
  This module represents Media field of SDP.

  For more details please see [RFC4566 Section 5.14](https://tools.ietf.org/html/rfc4566#section-5.14)
  """
  use Bunch
  @enforce_keys [:type, :ports, :protocol, :fmt]
  defstruct @enforce_keys ++
              [
                :title,
                {:connection_information, []},
                {:bandwidth, []},
                :encryption,
                {:attributes, []}
              ]

  alias Membrane.Protocol.SDP.{Encryption, Bandwidth, ConnectionInformation, Session}

  @type t :: %__MODULE__{
          type: binary(),
          ports: [:inet.port_number()],
          protocol: binary(),
          fmt: binary(),
          title: binary() | nil,
          connection_information: [ConnectionInformation.t()],
          bandwidth: [Bandwidth.t()],
          encryption: Encryption.t() | nil,
          attributes: [binary()]
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_media_spec | :malformed_port_number}
  def parse(media) do
    withl conn: [type, port, proto, fmt] <- String.split(media, " ", parts: 4),
          int: {port_no, port_options} when port_no in 0..65535 <- Integer.parse(port) do
      %__MODULE__{
        type: type,
        ports: gen_ports(port_no, port_options),
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

  def parse_optional(["c=" <> conn | rest], %__MODULE__{connection_information: info} = media) do
    with {:ok, conn} <- ConnectionInformation.parse(conn) do
      conn
      |> Bunch.listify()
      ~> %__MODULE__{media | connection_information: &1 ++ info}
      ~> parse_optional(rest, &1)
    end
  end

  def parse_optional(["b=" <> bandwidth | rest], %__MODULE__{bandwidth: acc_bandwidth} = media) do
    with {:ok, bandwidth} <- Bandwidth.parse(bandwidth) do
      %__MODULE__{media | bandwidth: [bandwidth | acc_bandwidth]}
      ~> parse_optional(rest, &1)
    end
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

  @spec apply_session(__MODULE__.t(), Session.t()) :: __MODULE__.t()
  def apply_session(media, session) do
    session
    |> Map.delete(:__struct__)
    |> Enum.reduce(media |> Map.delete(:__struct__), fn
      {inherited_key, value}, acc
      when inherited_key == :encryption ->
        if acc[inherited_key] != nil,
          do: acc,
          else: Map.put(acc, inherited_key, value)

      {inherited_key, value}, acc when inherited_key in [:connection_information, :bandwidth] ->
        if acc[inherited_key] != [],
          do: acc,
          else: Map.put(acc, inherited_key, value)

      _, acc ->
        acc
    end)
    ~> struct(__MODULE__, &1)
  end

  defp finalize_optional_parsing(%__MODULE__{attributes: attrs} = media) do
    attrs
    |> Enum.reverse()
    ~> %__MODULE__{media | attributes: &1}
  end

  defp gen_ports(port_no, port_options)

  defp gen_ports(port_no, "/" <> port_count) do
    port_count
    |> Integer.parse()
    ~> (
      {port_count, ""} ->
        port_no
        |> Stream.unfold(fn port_no -> {port_no, port_no + 2} end)
        |> Stream.take(port_count)
        |> Enum.into([])

      _ ->
        {:error, :invalid_port_count}
    )
  end

  defp gen_ports(port_no, _), do: [port_no]
end

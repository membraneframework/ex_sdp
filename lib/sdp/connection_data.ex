defmodule Membrane.Protocol.SDP.ConnectionData do
  @moduledoc """
  This module represents Connection Information.

  Address can be represented by either:
   - IPv4 address
   - IPv6 address
   - FQDN (Fully Qualified Domain Name)

  In case of IPv4 and IPv6 multicast addresses there can be more than one
  parsed from single SDP field if it is described using slash notation.

  Sessions using an IPv4 multicast connection address MUST also have
  a time to live (TTL) value present in addition to the multicast
  address.

  For more details please see [RFC4566 Section 5.7]|(https://tools.ietf.org/html/rfc4566#section-5.7
  """
  use Bunch

  @ipv4_max_value 255
  @ipv6_max_value 65_535

  @enforce_keys [:network_type, :address]
  defstruct @enforce_keys

  defmodule IP4 do
    @moduledoc false
    @enforce_keys [:value]
    defstruct @enforce_keys ++ [:ttl]

    @type t :: %__MODULE__{
            value: :inet.ip4_address(),
            ttl: 0..255 | nil
          }
  end

  defmodule IP6 do
    @moduledoc false
    @enforce_keys [:value]
    defstruct @enforce_keys

    @type t :: %__MODULE__{
            value: :inet.ip6_address()
          }
  end

  @type sdp_address :: IP6.t() | IP4.t()
  @type reason :: :invalid_address | :invalid_connection_data | :option_nan | :wrong_ttl

  @spec parse(binary()) :: {:ok, [sdp_address()] | sdp_address()} | {:error, reason}
  def parse(connection_string) do
    with [_nettype, addrtype, connection_address] <- String.split(connection_string, " "),
         [address | optional] <- String.split(connection_address, "/") do
      parse_address(address, addrtype, optional)
    else
      list when is_list(list) -> {:error, :invalid_connection_data}
    end
  end

  @spec serialize(sdp_address()) :: binary()
  def serialize(address) when not is_list(address) do
    with {:ok, serialized} <- serialize_address(address) do
      serialized
    end
  end

  @spec serialize([sdp_address()]) :: binary()
  def serialize(addresses) do
    case length(addresses) do
      0 ->
        ""

      size ->
        with {:ok, result} <- addresses |> Enum.sort_by(& &1.value) |> hd |> serialize_address do
          "c=" <> result <> serialize_size(size)
        end
    end
  end

  defp serialize_size(1), do: ""
  defp serialize_size(size) when size > 1, do: "/" <> Integer.to_string(size)

  @spec serialize_address(%IP4{ttl: nil}) :: {:ok, binary()} | {:error, any()}
  def serialize_address(%IP4{ttl: nil, value: value}) do
    with {:ok, address} <- serialize_address_value(value) do
      {:ok, "IN IP4 " <> address}
    end
  end

  @spec serialize_address(%IP4{ttl: 0..255}) :: {:ok, binary()} | {:error, any()}
  def serialize_address(%IP4{ttl: ttl, value: value}) do
    with {:ok, address} <- serialize_address_value(value) do
      {:ok, "IN IP4 " <> address <> "/" <> Integer.to_string(ttl)}
    end
  end

  @spec serialize_address(IP6.t()) :: {:ok, binary()} | {:error, any()}
  def serialize_address(%IP6{value: value}) do
    with {:ok, address} <- serialize_address_value(value) do
      {:ok, "IN IP6 " <> address}
    end
  end

  defp serialize_address_value(value) do
    with address <- :inet.ntoa(value) do
      {:ok, to_string(address)}
    end
  end

  defp parse_address(address, addrtype, optional) do
    with {:ok, address} <- address |> to_charlist() |> :inet.parse_address(),
         {:ok, addresses} <- handle_address(address, addrtype, optional) do
      {:ok, addresses}
    else
      {:error, :einval} -> {:ok, address}
      {:error, _} = error -> error
    end
  end

  defp handle_address(address, type, options)
  defp handle_address(address, "IP4", []), do: {:ok, %IP4{value: address}}

  defp handle_address(address, "IP4", [ttl]) do
    with {:ok, ttl} <- parse_ttl(ttl) do
      {:ok, %IP4{value: address, ttl: ttl}}
    end
  end

  defp handle_address(address, "IP4", [ttl, count]) do
    with {:ok, ttl} <- parse_ttl(ttl),
         {:ok, addresses} <- unfold_addresses(address, count, @ipv4_max_value) do
      addresses = Enum.map(addresses, fn address -> %IP4{value: address, ttl: ttl} end)
      {:ok, addresses}
    else
      wrong_ttl when is_number(wrong_ttl) -> {:error, :wrong_ttl}
      {:error, _} = error -> error
    end
  end

  defp handle_address(address, "IP6", []), do: {:ok, %IP6{value: address}}

  defp handle_address(address, "IP6", [count]) do
    with {:ok, addresses} <- unfold_addresses(address, count, @ipv6_max_value) do
      addresses = Enum.map(addresses, fn address -> %IP6{value: address} end)
      {:ok, addresses}
    end
  end

  defp handle_address(_, _, _), do: {:error, :invalid_address}

  defp parse_ttl(ttl) do
    ttl
    |> parse_numeric_option()
    ~>> ({:ok, ttl} when ttl not in 0..255 -> {:error, :wrong_ttl})
  end

  defp parse_numeric_option(option) do
    option
    |> Integer.parse()
    |> case do
      {number, ""} -> {:ok, number}
      _ -> {:error, :option_nan}
    end
  end

  # https://tools.ietf.org/html/rfc4566#page-15 defines a notation where
  # ip_ddress/count defines a sequence of consecuttive addresses, this function
  # creates such sequence.
  defp unfold_addresses(address, count, max_value) do
    with {:ok, count} <- parse_numeric_option(count) do
      0..(count - 1)
      |> Bunch.Enum.try_map(&offset_ip(address, &1, max_value))
    end
  end

  defp offset_ip(ip, offset, max_value) do
    index = tuple_size(ip) - 1
    value = elem(ip, index)

    if value + offset <= max_value do
      {:ok, put_elem(ip, index, value + offset)}
    else
      {:error, :invalid_address}
    end
  end
end

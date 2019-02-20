defmodule Membrane.Protocol.SDP.ConnectionInformation.Address do
  use Bunch
  @enforce_keys [:address]
  defstruct @enforce_keys ++ [:ttl, :count]

  @type t :: %__MODULE__{
          address: :inet.ip_address(),
          ttl: non_neg_integer(),
          count: non_neg_integer()
        }

  @spec parse(binary()) :: {:ok, t()} | {:error, :einval}
  def parse(address), do: address |> String.split("\/") |> parse_address()

  # TODO remove spec
  @spec parse_address([binary()]) :: {:error, :einval} | {:ok, t()}
  defp parse_address([address]), do: parse_address([address, nil, nil])
  defp parse_address([address, count]), do: parse_address([address, nil, count])

  defp parse_address([address, ttl, count]) do
    address = to_charlist(address)

    withl address: {:ok, address} <- :inet.parse_address(address),
          ttl_parse: {ttl, ""} <- parse_optional_int(ttl),
          count_parse: {count, ""} <- parse_optional_int(count) do
      %__MODULE__{
        address: address,
        ttl: ttl,
        count: count
      }
      ~> {:ok, &1}
    else
      address: _ -> {:error, :invalid_address}
      ttl_parse: _ -> {:error, :invalid_ttl}
      count_parse: _ -> {:error, :invalid_count}
    end
  end

  defp parse_address(_), do: {:error, :invalid_address}

  defp parse_optional_int(nil), do: {nil, ""}
  defp parse_optional_int(int) when is_binary(int), do: Integer.parse(int)
end

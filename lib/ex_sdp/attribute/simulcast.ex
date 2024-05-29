defmodule ExSDP.Attribute.Simulcast do
  @moduledoc """
  This module represents simulcast (RFC 8853).
  """

  defstruct send: [], recv: []

  @type rid() :: String.t()
  @type t :: %__MODULE__{
          send: [rid() | [rid()]],
          recv: [rid() | [rid()]]
        }

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :simulcast

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_simulcast}
  def parse(simulcast) do
    case String.split(simulcast, " ") do
      ["send", send] -> {:ok, "", send}
      ["recv", recv] -> {:ok, recv, ""}
      ["recv", recv, "send", send] -> {:ok, recv, send}
      ["send", send, "recv", recv] -> {:ok, recv, send}
      _other -> {:error, :invalid_simulcast}
    end
    |> case do
      {:ok, recv, send} ->
        send = parse_streams(send)
        recv = parse_streams(recv)
        {:ok, %__MODULE__{send: send, recv: recv}}

      {:error, _res} = err ->
        err
    end
  end

  defp parse_streams(""), do: []

  defp parse_streams(streams) do
    streams
    |> String.split(";")
    |> Enum.map(&String.split(&1, ","))
    |> Enum.map(fn
      [rid] -> rid
      rids -> rids
    end)
  end
end

defimpl String.Chars, for: ExSDP.Attribute.Simulcast do
  alias ExSDP.Attribute.Simulcast

  @impl true
  def to_string(simulcast) do
    %Simulcast{send: send, recv: recv} = simulcast
    send = encode_streams(send)
    send = if(send == "", do: [], else: ["send", send])
    recv = encode_streams(recv)
    recv = if(recv == "", do: [], else: ["recv", recv])
    send_recv = Enum.join(send ++ recv, " ")

    "simulcast:#{send_recv}"
  end

  defp encode_streams(streams) do
    Enum.map_join(streams, ";", fn
      rids when is_list(rids) -> Enum.join(rids, ",")
      rid -> rid
    end)
  end
end

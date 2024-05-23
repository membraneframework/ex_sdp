defmodule ExSDP.Attribute.RID do
  @moduledoc """
  This module represents rid (RFC 8851).
  """

  @enforce_keys [:id, :direction]
  defstruct @enforce_keys ++ [pt: nil, restrictions: []]

  @type t :: %__MODULE__{
          id: binary(),
          direction: :send | :recv,
          pt: [non_neg_integer()] | nil,
          restrictions: {String.t(), String.t()}
        }

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :rid

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_rid}
  def parse(rid) do
    case String.split(rid, " ") do
      [id, dir] when dir in ["send", "recv"] -> {:ok, id, dir, ""}
      [id, dir, rests] when dir in ["send", "recv"] -> {:ok, id, dir, rests}
      _other -> {:error, :invalid_rid}
    end
    |> case do
      {:ok, id, dir, rests} ->
        {pt, rests} = parse_restrictions(rests)
        dir = String.to_atom(dir)
        {:ok, %__MODULE__{id: id, direction: dir, pt: pt, restrictions: rests}}

      {:error, _res} = err ->
        err
    end
  end

  defp parse_restrictions(rests) do
    case String.split(rests, ";") do
      ["pt=" <> pts | rests] ->
        pts =
          pts
          |> String.split(",")
          |> Enum.map(&Integer.parse(&1, 10))
          |> Enum.flat_map(fn
            {int, _} -> [int]
            :error -> []
          end)

        {pts, do_parse_restrictions(rests)}

      rests ->
        {nil, do_parse_restrictions(rests)}
    end
  end

  defp do_parse_restrictions(rests) do
    rests
    |> Enum.flat_map(fn rest ->
      case String.split(rest, "=", parts: 2) do
        [restriction, value] -> [{restriction, value}]
        _other -> []
      end
    end)
  end
end

defimpl String.Chars, for: ExSDP.Attribute.RID do
  alias ExSDP.Attribute.RID

  @impl true
  def to_string(rid) do
    %RID{id: id, direction: direction, pt: pt, restrictions: rests} = rid
    direction = Atom.to_string(direction)

    pts =
      case pt do
        nil -> []
        pts -> ["pt=#{Enum.join(pts, ",")}"]
      end

    rests = Enum.map(rests, fn {rest, value} -> "#{rest}=#{value}" end)

    pt_rests =
      (pts ++ rests)
      |> Enum.join(";")

    all =
      [id, direction, pt_rests]
      |> Enum.reject(&(&1 == ""))
      |> Enum.join(" ")

    "rid:#{all}"
  end
end

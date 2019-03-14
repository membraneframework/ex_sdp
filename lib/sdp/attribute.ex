defmodule Membrane.Protocol.SDP.Attribute do
  @moduledoc """
  This module is responsible for parsing SDP Attributes.
  """
  use Bunch

  alias __MODULE__.RTPMapping

  @valid_flags ["recvonly", "sendrecv", "sendonly", "inactive"]
  @directly_assignable [
    "cat",
    "keywds",
    "tool",
    "orient",
    "type",
    "charset",
    "sdplang",
    "lang"
  ]
  @numeric ["ptime", "maxptime", "quality"]

  @doc """
  Parses SPD Attribute.

  Value attributes formatted as `name:value` shall be parsed as `{name, value}`
  other will be treated as property (flag) attributes.
  Known attributes' names will be converted into atoms.
  """
  @spec parse(binary()) :: {:ok, atom() | tuple()} | {:error, atom()}
  def parse(line) do
    line
    |> String.split(":", parts: 2)
    |> case do
      [name, value] ->
        name = String.replace(name, "-", "-")

        {name, value}

      [flag] ->
        flag
    end
    |> handle_known_attribute()
  end

  defp handle_known_attribute(attr)

  defp handle_known_attribute({"rtpmap", mapping}) do
    mapping
    |> RTPMapping.parse()
    ~>> ({:ok, result} -> {:ok, {:rtpmap, result}})
  end

  defp handle_known_attribute({"framerate", framerate}) do
    with {:ok, framerate} <- parse_framerate(framerate) do
      {:ok, {:framerate, framerate}}
    end
  end

  defp handle_known_attribute(flag) when is_binary(flag) and flag in @valid_flags do
    String.to_atom(flag)
    ~> {:ok, &1}
  end

  defp handle_known_attribute({prop, value})
       when is_binary(prop) and prop in @directly_assignable do
    {String.to_atom(prop), value}
    ~> {:ok, &1}
  end

  defp handle_known_attribute({prop, value}) when is_binary(prop) and prop in @numeric do
    with {number, ""} <- Integer.parse(value) do
      {String.to_atom(prop), number}
      ~> {:ok, &1}
    else
      _ -> {:error, :invalid_attribute}
    end
  end

  defp handle_known_attribute(other), do: other ~> {:ok, &1}

  def parse_framerate(framerate) do
    case Float.parse(framerate) do
      {float_framerate, ""} ->
        {:ok, float_framerate}

      _ ->
        parse_compound_framerate(framerate)
    end
  end

  defp parse_compound_framerate(framerate) do
    with {left, "/" <> right} <- Integer.parse(framerate),
         {right, ""} <- Integer.parse(right) do
      {:ok, {left, right}}
    else
      _ -> {:error, :invalid_framerate}
    end
  end
end

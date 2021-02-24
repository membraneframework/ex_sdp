defmodule ExSDP.Utils do
  @moduledoc false

  def split(origin, delim, expected_len) do
    split = String.split(origin, delim, parts: expected_len)
    if length(split) == expected_len, do: {:ok, split}, else: {:error, :too_few_fields}
  end

  def parse_numeric_string(string) do
    case Integer.parse(string) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :string_nan}
    end
  end

  def parse_numeric_hex_string(string) do
    case Integer.parse(string, 16) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :string_not_hex}
    end
  end

  def parse_numeric_bool_string(string) do
    case Integer.parse(string) do
      {0, ""} -> {:ok, false}
      {1, ""} -> {:ok, true}
      _ -> {:error, :string_not_0_nor_1}
    end
  end
end

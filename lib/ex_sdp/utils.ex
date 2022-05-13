defmodule ExSDP.Utils do
  @moduledoc false

  @spec split(binary, binary | [binary] | :binary.cp() | Regex.t(), any) ::
          {:error, :too_few_fields} | {:ok, [binary]}
  def split(origin, delim, expected_len) do
    split = String.split(origin, delim, parts: expected_len)
    if length(split) == expected_len, do: {:ok, split}, else: {:error, :too_few_fields}
  end

  @spec parse_numeric_string(binary) :: {:error, :string_nan} | {:ok, integer}
  def parse_numeric_string(string) do
    case Integer.parse(string) do
      {number, ""} -> {:ok, number}
      _string_nan -> {:error, :string_nan}
    end
  end

  @spec parse_numeric_hex_string(binary) :: {:error, :string_not_hex} | {:ok, integer}
  def parse_numeric_hex_string(string) do
    case Integer.parse(string, 16) do
      {number, ""} -> {:ok, number}
      _string_not_hex -> {:error, :string_not_hex}
    end
  end

  @spec parse_numeric_bool_string(binary) :: {:error, :string_not_0_nor_1} | {:ok, boolean}
  def parse_numeric_bool_string(string) do
    case Integer.parse(string) do
      {0, ""} -> {:ok, false}
      {1, ""} -> {:ok, true}
      _string_not_0_nor_1 -> {:error, :string_not_0_nor_1}
    end
  end
end

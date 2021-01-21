defmodule ExSDP.Utils do
  @moduledoc false

  def split(origin, delim, expected_len) do
    split = String.split(origin, delim)
    if length(split) == expected_len, do: {:ok, split}, else: {:error, :too_few_fields}
  end

  def parse_numeric_string(string) do
    case Integer.parse(string) do
      {number, ""} -> {:ok, number}
      _ -> {:error, :string_nan}
    end
  end
end

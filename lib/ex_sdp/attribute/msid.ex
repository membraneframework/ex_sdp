defmodule ExSDP.Attribute.Msid do
  @moduledoc """
  This module represents msid (RFC 8830).
  """

  @enforce_keys [:id]
  defstruct @enforce_keys ++ [:app_data]

  @type t :: %__MODULE__{id: binary(), app_data: binary() | nil}

  @spec new(id :: binary(), app_data :: binary() | nil) :: t()
  def new(id \\ generate_random(), app_data \\ generate_random()) do
    %__MODULE__{id: id, app_data: app_data}
  end

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :msid

  @doc """
  Generates random, by default 36 char string that can be used as `id` or `app_data`.

  String is built from letters `a-z` digits `0-9` and `-`.
  Although this char set doesn't contain all possible chars it meets the requirements
  described in RFC 8830.
  """
  @spec generate_random(length :: 1..64) :: binary()
  def generate_random(length \\ 36) do
    char_set = Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9) ++ [?-]
    for _ <- 1..length, into: "", do: <<Enum.random(char_set)>>
  end

  @spec parse(binary()) :: {:ok, t()} | {:error, :invalid_msid}
  def parse(msid) do
    case String.split(msid, " ") do
      [""] ->
        {:error, :invalid_msid}

      ["", _app_data] ->
        {:error, :invalid_msid}

      [id] ->
        {:ok, %__MODULE__{id: id}}

      [id, app_data] ->
        msid = %__MODULE__{
          id: id,
          app_data: app_data
        }

        {:ok, msid}

      _ ->
        {:error, :invalid_msid}
    end
  end
end

defimpl String.Chars, for: ExSDP.Attribute.Msid do
  alias ExSDP.Attribute.Msid

  def to_string(%Msid{id: id, app_data: nil}), do: "msid:#{id}"
  def to_string(%Msid{id: id, app_data: app_data}), do: "msid:#{id} #{app_data}"
end

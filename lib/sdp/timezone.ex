defmodule Membrane.Protocol.SDP.Timezone do
  use Bunch
  @enforce_keys [:adjustment_time, :offset]
  defstruct @enforce_keys

  @type t :: %__MODULE__{
          adjustment_time: non_neg_integer(),
          offset: binary()
        }

  @spec parse(binary()) :: {:ok, [t]} | {:error, :invalid_timezone}
  def parse(timezones) do
    timezones
    |> String.split(" ")
    # Maybe this should be checked?
    ~> (
      list when rem(length(list), 2) == 0 ->
        list
        |> Enum.chunk_every(2)
        |> Enum.map(fn [adjustment_time, offset] ->
          {adjustment_time, ""} = Integer.parse(adjustment_time)

          %__MODULE__{
            adjustment_time: adjustment_time,
            offset: offset
          }
        end)
        ~> {:ok, &1}

      _ ->
        {:error, :invalid_timezone}
    )
  end
end

defmodule Membrane.Protocol.SDP.RepeatTimesTest do
  use ExUnit.Case
  alias Membrane.Protocol.SDP.RepeatTimes

  # TODO test invalid behaviour
  # TODO parse short syntax

  describe "Repeat Times parser" do
    test "process a valid declaration" do
      assert {:ok, result} = RepeatTimes.parse("604800 3600 0 90000")

      assert %Membrane.Protocol.SDP.RepeatTimes{
               active_duration: 3600,
               offsets: [0, 90000],
               repeat_interval: 604_800
             } = result
    end
  end
end

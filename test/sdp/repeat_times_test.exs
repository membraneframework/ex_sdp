defmodule Membrane.Protocol.SDP.RepeatTimesTest do
  use ExUnit.Case
  alias Membrane.Protocol.SDP.RepeatTimes

  describe "Repeat Times parses compact format" do
    test "process a valid compact declaration" do
      assert {:ok, result} = RepeatTimes.parse("6d 6h 10s 90m")

      assert %RepeatTimes{
               active_duration: 21_600,
               offsets: [10, 5_400],
               repeat_interval: 518_400
             } = result
    end

    test "returns an error if compact format has illegal option" do
      assert {:error, {:invalid_unit, "g"}} = RepeatTimes.parse("6d 6h 10g 90m")
    end

    test "returns an error if no offsets are given in compact format" do
      assert {:error, :no_offsets} == RepeatTimes.parse("6d 6h")
    end

    test "return an error if repeat does not have has no interval nor duration" do
      assert {:error, :malformed_repeat} == RepeatTimes.parse("6d")
    end
  end

  describe "Repeat Times parses explicit format" do
    test "process a valid declaration" do
      assert {:ok, result} = RepeatTimes.parse("604800 3600 0 90000")

      assert %RepeatTimes{
               active_duration: 3600,
               offsets: [0, 90_000],
               repeat_interval: 604_800
             } = result
    end

    test "returns an error if no offsets are given" do
      assert {:error, :no_offsets} == RepeatTimes.parse("6000 60")
    end

    test "return an error if offest is not valid" do
      assert {:error, {:invalid_offset, "64er"}} == RepeatTimes.parse("600 600 64er")
    end

    test "returns an error if either duration or interval is not a number" do
      assert {:error, :malformed_repeat} == RepeatTimes.parse("600d3e3 60 30")
      assert {:error, :malformed_repeat} == RepeatTimes.parse("60 600d3e3 30")
    end
  end
end

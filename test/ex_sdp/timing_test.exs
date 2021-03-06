defmodule ExSDP.TimingTest do
  use ExUnit.Case

  alias ExSDP.Timing

  describe "Timing parser" do
    test "processes valid description" do
      assert {:ok, timing} = Timing.parse("1550678539 1550878520")
      assert timing == %Timing{start_time: 1_550_678_539, stop_time: 1_550_878_520}
    end

    test "returns an error when description is invalid" do
      assert {:error, :invalid_timing} = Timing.parse("")
    end

    test "returns an error when either stop or start is nan" do
      assert {:error, :time_nan} = Timing.parse("1550s678539 1550878520")
      assert {:error, :time_nan} = Timing.parse("1550678539 155s0878520")
    end
  end

  describe "Timing serializer" do
    test "serializes valid timing" do
      timing = %Timing{start_time: 2_208_988_800, stop_time: 2_208_988_898}
      assert "#{timing}" == "2208988800 2208988898"
    end
  end
end

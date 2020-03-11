defmodule Membrane.Protocol.SDP.TimezoneTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Timezone

  describe "Timezone parser" do
    test "processes valid timezone correction description" do
      assert {:ok, corrections} = Timezone.parse("2882844526 -1h 2898848070 0")

      assert corrections == [
               %Timezone{adjustment_time: 2_882_844_526, offset: -1},
               %Timezone{adjustment_time: 2_898_848_070, offset: 0}
             ]
    end

    test "returns an error if base time does not have corresponding timezone" do
      assert {:error, :invalid_timezone} = Timezone.parse("2882844526 -1h 2898848070")
    end

    test "returns an error if one of base times is not valid" do
      assert {:error, :invalid_timezone} = Timezone.parse("2882844526 -1h 28988ds4a8dd0a70 1h")
    end
  end

  describe "Timezone serializer" do
    test "serializes empty list" do
      assert Timezone.serialize([]) == ""
    end

    test "serializes multiple adjustments" do
      timezones = [
        %Timezone{adjustment_time: 1, offset: -1},
        %Timezone{adjustment_time: 2, offset: 0}
      ]

      assert Timezone.serialize(timezones) == "z=1 -1h 2 0"
    end
  end
end

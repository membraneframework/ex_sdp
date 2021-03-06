defmodule ExSDP.TimezoneTest do
  use ExUnit.Case

  alias ExSDP.Timezone
  alias ExSDP.Timezone.Correction

  describe "Timezone parser" do
    test "processes valid timezone correction description" do
      assert {:ok, corrections} = Timezone.parse("2882844526 -1h 2898848070 0")

      assert corrections == %Timezone{
               corrections: [
                 %Correction{adjustment_time: 2_882_844_526, offset: -1},
                 %Correction{adjustment_time: 2_898_848_070, offset: 0}
               ]
             }
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
      timezone = %Timezone{corrections: []}
      assert "#{timezone}" == ""
    end

    test "serializes multiple corrections" do
      timezone = %Timezone{
        corrections: [
          %Correction{adjustment_time: 1, offset: -1},
          %Correction{adjustment_time: 2, offset: 0}
        ]
      }

      assert "#{timezone}" == "1 -1h 2 0"
    end
  end
end

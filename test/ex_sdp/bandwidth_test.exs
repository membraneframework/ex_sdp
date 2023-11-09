defmodule ExSDP.BandwidthTest do
  use ExUnit.Case

  alias ExSDP.Bandwidth

  describe "Bandwidth parses" do
    test "valid property" do
      assert {:ok, result} = Bandwidth.parse("CT:128")
      assert %Bandwidth{type: :CT, bandwidth: 128} == result
    end

    test "parse TIAS bandwidth type" do
      assert {:ok, result} = Bandwidth.parse("TIAS:256000")
      assert %Bandwidth{type: :TIAS, bandwidth: 256000} == result
    end

    test "returns error when property is invalid" do
      assert {:error, :invalid_bandwidth} == Bandwidth.parse("gibberish")
    end
  end

  describe "Bandwidth serializer" do
    test "serializes valid bandwidth" do
      bandwidth = %Bandwidth{type: :CT, bandwidth: 128}
      assert "#{bandwidth}" == "CT:128"
    end
  end
end

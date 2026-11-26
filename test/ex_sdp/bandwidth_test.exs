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
      assert %Bandwidth{type: :TIAS, bandwidth: 256_000} == result
    end

    test "parse RS and RR bandwidth types" do
      assert {:ok, %Bandwidth{type: :RS, bandwidth: 0}} == Bandwidth.parse("RS:0")
      assert {:ok, %Bandwidth{type: :RR, bandwidth: 4000}} == Bandwidth.parse("RR:4000")
      assert "#{%Bandwidth{type: :RR, bandwidth: 4000}}" == "RR:4000"
    end

    test "returns error when property is invalid" do
      assert {:error, :invalid_bandwidth} == Bandwidth.parse("gibberish")
    end

    test "returns error when the type is unknown" do
      assert {:error, :unknown_type} == Bandwidth.parse("X-YZ:256")
    end
  end

  describe "Bandwidth serializer" do
    test "serializes valid bandwidth" do
      bandwidth = %Bandwidth{type: :CT, bandwidth: 128}
      assert "#{bandwidth}" == "CT:128"
    end
  end
end

defmodule Membrane.Protocol.SDP.BandwidthTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Bandwidth

  describe "Bandwidth parses" do
    test "valid property" do
      assert {:ok, result} = Bandwidth.parse("CW:128")
      assert %Bandwidth{type: "CW", bandwidth: "128"}
    end

    test "returns error when property is invalid" do
      assert {:error, :invalid_bandwidth} == Bandwidth.parse("gibberish")
    end
  end
end

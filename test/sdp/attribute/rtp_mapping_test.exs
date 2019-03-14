defmodule Membrane.Protocol.SDP.Attribute.RTPMappingTest do
  use ExUnit.Case
  alias Membrane.Protocol.SDP.Attribute.RTPMapping

  describe "RTP Mapping parser" do
    test "parses valid rtp mapping" do
      assert {:ok, mapping} = RTPMapping.parse("99 h263-1998/90000")

      assert %RTPMapping{
               payload_type: 99,
               encoding: "h263-1998",
               clock_rate: 90_000
             } = mapping
    end

    test "returns an error when clock_rate or payload type is not a number" do
      assert {:error, :invalid_attribute} = RTPMapping.parse("9t9 h264/90000")
    end
  end
end

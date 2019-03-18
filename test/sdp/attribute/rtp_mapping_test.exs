defmodule Membrane.Protocol.SDP.Attribute.RTPMappingTest do
  use ExUnit.Case
  alias Membrane.Protocol.SDP.Attribute.RTPMapping

  describe "RTP Mapping parser" do
    test "parses valid rtp mapping for video media" do
      assert {:ok, mapping} = RTPMapping.parse("99 h263-1998/90000", :video)

      assert %RTPMapping{
               payload_type: 99,
               encoding: "h263-1998",
               clock_rate: 90_000
             } = mapping
    end

    # a=rtpmap:97 L16/8000#
    # a=rtpmap:98 L16/11025/2

    test "parses valid rtp mapping for audio media without specified channels" do
      assert {:ok, mapping} = RTPMapping.parse("97 L16/8000", :audio)

      assert %RTPMapping{
               payload_type: 97,
               encoding: "L16",
               clock_rate: 8_000,
               params: [{:channels_count, 1}]
             } = mapping
    end

    test "parses valid rtp mapping for audio media with specified channels" do
      assert {:ok, mapping} = RTPMapping.parse("112 L16/8000/2", :audio)

      assert %RTPMapping{
               payload_type: 112,
               encoding: "L16",
               clock_rate: 8_000,
               params: [{:channels_count, 2}]
             } = mapping
    end

    test "returns an error when clock_rate or payload type is not a number" do
      assert {:error, :invalid_attribute} = RTPMapping.parse("9t9 h264/90000", :video)
    end
  end
end

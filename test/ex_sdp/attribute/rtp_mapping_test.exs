defmodule ExSDP.Attribute.RTPMappingTest do
  use ExUnit.Case

  alias ExSDP.Attribute.RTPMapping

  describe "RTP Mapping parser" do
    test "parses valid rtp mapping for video media" do
      assert {:ok, mapping} = RTPMapping.parse("99 h263-1998/90000", media_type: :video)

      assert %RTPMapping{
               payload_type: 99,
               encoding: "h263-1998",
               clock_rate: 90_000
             } = mapping
    end

    test "parses valid rtp mapping for audio media without specified channels" do
      assert {:ok, mapping} = RTPMapping.parse("97 L16/8000", media_type: :audio)

      assert %RTPMapping{
               payload_type: 97,
               encoding: "L16",
               clock_rate: 8_000,
               params: 1
             } = mapping
    end

    test "parses valid rtp mapping for audio media with specified channels" do
      assert {:ok, mapping} = RTPMapping.parse("112 L16/8000/2", media_type: :audio)

      assert %RTPMapping{
               payload_type: 112,
               encoding: "L16",
               clock_rate: 8_000,
               params: 2
             } = mapping
    end

    test "returns an error when clock_rate or payload type is not a number" do
      assert {:error, :invalid_pt} = RTPMapping.parse("9t9 h264/90000", media_type: :video)
      assert {:error, :string_nan} = RTPMapping.parse("99 h264/r0000", media_type: :video)
    end
  end

  describe "RTP Mapping serializer" do
    test "serializes mapping without parameter" do
      mapping = %RTPMapping{
        payload_type: 101,
        encoding: "h263-1998",
        clock_rate: 90_000
      }

      assert "#{mapping}" == "rtpmap:101 h263-1998/90000"
    end

    test "serializes mapping with parameter" do
      mapping = %RTPMapping{
        payload_type: 98,
        encoding: "L16",
        clock_rate: 11_025,
        params: 2
      }

      assert "#{mapping}" == "rtpmap:98 L16/11025/2"
    end
  end
end

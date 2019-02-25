defmodule Membrane.Protocol.SDP.MediaTest do
  use ExUnit.Case
  use Bunch

  alias Membrane.Protocol.SDP.Media
  alias Membrane.Support.SpecHelper

  describe "Media parser" do
    test "processes valid media description" do
      assert {:ok, media} =
               "video 49170 RTP/AVP 31"
               |> Media.parse(SpecHelper.empty_session())

      assert %Media{
               fmt: "31",
               ports: [49170],
               protocol: "RTP/AVP",
               type: "video"
             } = media
    end

    test "processes valid media description with multiple ports" do
      assert {:ok, media} =
               "video 49170/2 RTP/AVP 31"
               |> Media.parse(SpecHelper.empty_session())

      assert %Media{
               fmt: "31",
               ports: [49170, 49172],
               protocol: "RTP/AVP",
               type: "video"
             } = media
    end

    test "processes media with attributes" do
      media = "m=audio 49230 RTP/AVP 96 97 98"

      attributes =
        """
        a=rtpmap:96 L8/8000
        a=rtpmap:97 L16/8000
        a=rtpmap:98 L16/11025/2
        """
        |> String.split("\n")

      {:ok, {[""], medium}} =
        media
        |> Media.parse(SpecHelper.empty_session())
        ~>> ({:ok, medium} -> Media.parse_optional(attributes, medium))

      assert %Media{
               attributes: ["rtpmap:96 L8/8000", "rtpmap:97 L16/8000", "rtpmap:98 L16/11025/2"],
               fmt: "96 97 98",
               ports: [49230],
               protocol: "RTP/AVP",
               type: "m=audio"
             } = medium
    end
  end
end

defmodule ExSDP.LenientParsingTest do
  @moduledoc """
  Descriptions as RTSP servers in IP cameras and recorders produce them.

  Each deviation below is tolerated by at least one of libavformat (whose SDP parser
  never fails), GStreamer (likewise) and gortsplib (whose parser has a test case named
  after the device for most of them); the references next to the cases point there.
  """
  use ExUnit.Case, async: true

  import ExUnit.CaptureLog

  alias ExSDP.Attribute.{FMTP, RTPMapping}

  defp sdp(lines), do: Enum.map_join(lines, &(&1 <> "\r\n"))

  defp session(session_lines, media_lines \\ ["m=video 0 RTP/AVP 96", "a=rtpmap:96 H264/90000"]) do
    sdp(["v=0"] ++ session_lines ++ media_lines)
  end

  defp parse_leniently(input) do
    assert {:error, _reason} = ExSDP.parse(input)

    {result, log} = with_log(fn -> ExSDP.parse(input, lenient: true) end)
    assert {:ok, %ExSDP{} = sdp} = result
    assert log =~ "[warning]"
    assert ExSDP.parse!(input, lenient: true) == sdp

    {sdp, log}
  end

  describe "a line of the session section that cannot be parsed is skipped:" do
    for {description, line} <- [
          {"an origin whose user name contains spaces", "o=RTSP Session 1 2 IN IP4 0.0.0.0"},
          {"an origin that ends after the network type", "o=- 1 1 IN"},
          {"an origin with a misspelt address type", "o=- 1 1 IN IPV4 10.0.0.1"},
          {"an origin with a fractional session id", "o=- 1.5 1 IN IP4 10.0.0.1"}
        ] do
      test description do
        {sdp, log} = parse_leniently(session([unquote(line), "s=x", "t=0 0"]))

        assert sdp.origin == nil
        assert sdp.session_name == "x"
        assert [%ExSDP.Media{type: :video}] = sdp.media
        assert log =~ unquote(line)
      end
    end

    for {description, line} <- [
          {"connection data without an address", "c=IN "},
          {"connection data with a repeated prefix", "c=IN c=IN IP4 0.0.0.0"}
        ] do
      test description do
        {sdp, log} = parse_leniently(session(["o=- 1 1 IN IP4 10.0.0.1", "s=x", unquote(line)]))

        assert sdp.connection_data == nil
        assert [%ExSDP.Media{type: :video}] = sdp.media
        assert log =~ unquote(line)
      end
    end

    test "a timing that is not a pair of numbers" do
      {sdp, log} = parse_leniently(session(["o=- 1 1 IN IP4 10.0.0.1", "s=x", "t=now-"]))

      assert sdp.timing == nil
      assert log =~ "t=now-"
    end

    test "a bandwidth of an experimental type" do
      {sdp, log} = parse_leniently(session(["s=x", "b=X-AV:100"]))

      assert sdp.bandwidth == []
      assert log =~ "b=X-AV:100"
    end

    test "a line of an unknown type" do
      {sdp, log} = parse_leniently(session(["s=x", "y=0100000001"]))

      assert sdp.session_name == "x"
      assert log =~ "y=0100000001"
    end
  end

  describe "a line of a media section that cannot be parsed is skipped:" do
    test "a line that belongs to the session section" do
      {sdp, log} =
        parse_leniently(
          session(
            ["s=x"],
            ["m=video 0 RTP/AVP 98", "t=0 0", "a=rtpmap:98 H264/90000", "a=control:trackID=1"]
          )
        )

      assert [%ExSDP.Media{attributes: [%RTPMapping{encoding: "H264"}, {"control", "trackID=1"}]}] =
               sdp.media

      assert log =~ "t=0 0"
    end

    test "connection data that is not an address" do
      {sdp, _log} =
        parse_leniently(
          session(["s=x"], ["m=audio 0 RTP/AVP 0", "c=SM SM spk0_trackID2", "a=control:trackID=2"])
        )

      assert [
               %ExSDP.Media{
                 type: :audio,
                 connection_data: nil,
                 attributes: [{"control", "trackID=2"}]
               }
             ] =
               sdp.media
    end

    test "only that line is lost, not the media sections around it" do
      {sdp, _log} =
        parse_leniently(
          session(["s=x"], [
            "m=video 0 RTP/AVP 96",
            "b=X-AV:100",
            "a=rtpmap:96 H264/90000",
            "m=audio 0 RTP/AVP 8",
            "a=control:trackID=2"
          ])
        )

      assert [
               %ExSDP.Media{type: :video, attributes: [%RTPMapping{}]},
               %ExSDP.Media{type: :audio, fmt: [8], attributes: [{"control", "trackID=2"}]}
             ] = sdp.media
    end
  end

  describe "a media line" do
    test "with a format that is not a payload type keeps the format as it is written" do
      {sdp, log} =
        parse_leniently(
          session(["s=x"], [
            "m=video 0 RTP/AVP 96",
            "a=rtpmap:96 H264/90000",
            "m=application 0 RTP/AVP smart/1/90000",
            "a=rtpmap:95 TP-LINK/90000",
            "a=control:track3"
          ])
        )

      assert [
               %ExSDP.Media{type: :video, fmt: [96]},
               %ExSDP.Media{
                 type: :application,
                 fmt: "smart/1/90000",
                 attributes: [%RTPMapping{payload_type: 95, encoding: "TP-LINK"}, _control]
               }
             ] = sdp.media

      assert log =~ "smart/1/90000"
    end

    test "that cannot be parsed at all takes its whole section with it" do
      {sdp, log} =
        parse_leniently(
          session(["s=x"], [
            "m=video",
            "a=rtpmap:96 H264/90000",
            "a=control:trackID=1",
            "m=audio 0 RTP/AVP 8",
            "a=control:trackID=2"
          ])
        )

      assert sdp.attributes == []
      assert [%ExSDP.Media{type: :audio, attributes: [{"control", "trackID=2"}]}] = sdp.media
      assert log =~ "m=video"
    end
  end

  describe "an attribute whose value cannot be parsed is kept as it is written:" do
    test "rtpmap without a clock rate" do
      {sdp, log} =
        parse_leniently(session(["s=x"], ["m=application 0 RTP/AVP 107", "a=rtpmap:107 custom"]))

      assert [%ExSDP.Media{attributes: [{"rtpmap", "107 custom"}]}] = sdp.media
      assert ExSDP.get_attribute(hd(sdp.media), :rtpmap) == nil
      assert log =~ "rtpmap:107 custom"
    end

    test "framerate that is not a number" do
      {sdp, _log} =
        parse_leniently(session(["s=x"], ["m=video 0 RTP/AVP 96", "a=framerate:25fps"]))

      assert [%ExSDP.Media{attributes: [{"framerate", "25fps"}]}] = sdp.media
    end

    test "fmtp without parameters" do
      {sdp, _log} = parse_leniently(session(["s=x"], ["m=video 0 RTP/AVP 96", "a=fmtp:96"]))

      assert [%ExSDP.Media{attributes: [{"fmtp", "96"}]}] = sdp.media
    end

    test "an attribute that needs a value and has none is kept as a flag" do
      {sdp, _log} = parse_leniently(session(["s=x"], ["m=video 0 RTP/AVP 96", "a=rtpmap"]))

      assert [%ExSDP.Media{attributes: ["rtpmap"]}] = sdp.media
    end

    test "at the session level too" do
      {sdp, _log} = parse_leniently(session(["s=x", "a=type:unheard-of"]))

      assert sdp.attributes == [{"type", "unheard-of"}]
    end
  end

  describe "an fmtp parameter whose value cannot be parsed is moved to :unknown:" do
    defp parse_fmtp_leniently(params) do
      {sdp, log} =
        parse_leniently(session(["s=x"], ["m=video 0 RTP/AVP 96", "a=fmtp:96 " <> params]))

      assert [%ExSDP.Media{attributes: [%FMTP{pt: 96} = fmtp]}] = sdp.media
      {fmtp, log}
    end

    test "sprop-parameter-sets that is not base64" do
      {fmtp, log} =
        parse_fmtp_leniently("packetization-mode=1;sprop-parameter-sets=Z0IAH5W!!,aM48gA==")

      assert fmtp.packetization_mode == 1
      assert fmtp.sprop_parameter_sets == nil
      assert fmtp.unknown == ["sprop-parameter-sets=Z0IAH5W!!,aM48gA=="]
      assert log =~ "sprop-parameter-sets"
    end

    test "sprop-parameter-sets with a single parameter set" do
      {fmtp, _log} =
        parse_fmtp_leniently("packetization-mode=1;sprop-parameter-sets=Z0IAH5WoFAFuQA==")

      assert fmtp.packetization_mode == 1
      assert fmtp.sprop_parameter_sets == nil
      assert fmtp.unknown == ["sprop-parameter-sets=Z0IAH5WoFAFuQA=="]
    end

    test "profile-level-id that is not hexadecimal" do
      {fmtp, _log} = parse_fmtp_leniently("profile-level-id=xyz;packetization-mode=1")

      assert fmtp.profile_level_id == nil
      assert fmtp.packetization_mode == 1
      assert fmtp.unknown == ["profile-level-id=xyz"]
    end

    test "a parameter that is neither a key and a value nor a list of tones or payloads" do
      {fmtp, _log} = parse_fmtp_leniently("packetization-mode=1;h3c-v3")

      assert fmtp.packetization_mode == 1
      assert fmtp.unknown == ["h3c-v3"]
    end

    test "FMTP.parse/2 does the same and FMTP.parse/1 stays strict" do
      fmtp = "96 packetization-mode=1;profile-level-id=xyz"

      assert {:error, :string_not_hex} = FMTP.parse(fmtp)

      {result, _log} = with_log(fn -> FMTP.parse(fmtp, lenient: true) end)
      assert {:ok, %FMTP{packetization_mode: 1, unknown: ["profile-level-id=xyz"]}} = result
    end
  end

  test "a line that cannot be parsed never makes lenient parsing raise" do
    for line <- [
          "m=video 0-1 RTP/AVP 96",
          "c=IN IP4 " <> <<0xFF, 0xFE>>,
          "o=- 1 1 IN IP4 " <> <<0xFF, 0xFE>>,
          "r=7d 1h 0 25h x",
          "a=rtpmap:" <> <<0xFF>>,
          "a=fmtp:96 " <> <<0xFF, 0x3D, 0xFF>>,
          "z=" <> <<0xFF>>,
          "k=" <> <<0xFF>>
        ] do
      {result, _log} = with_log(fn -> ExSDP.parse(session(["s=x", line]), lenient: true) end)
      assert {:ok, %ExSDP{session_name: "x"}} = result
    end
  end

  test "a description that needs no leniency is parsed the same with and without it" do
    input =
      sdp([
        "v=0",
        "o=- 1109162014219182 1109162014219192 IN IP4 10.0.0.1",
        "s=Media Presentation",
        "e=NONE",
        "c=IN IP4 0.0.0.0",
        "t=0 0",
        "a=control:*",
        "m=video 0 RTP/AVP 96",
        "b=AS:5000",
        "a=rtpmap:96 H264/90000",
        "a=fmtp:96 profile-level-id=4D0014;packetization-mode=1;sprop-parameter-sets=Z0IAH5WoFAFuQA==,aM48gA==",
        "a=control:trackID=1",
        "m=audio 0 RTP/AVP 0",
        "a=rtpmap:0 PCMU/8000",
        "a=control:trackID=2"
      ])

    {result, log} = with_log(fn -> ExSDP.parse(input, lenient: true) end)

    assert {:ok, sdp} = result
    assert {:ok, sdp} == ExSDP.parse(input)
    assert log == ""
  end
end

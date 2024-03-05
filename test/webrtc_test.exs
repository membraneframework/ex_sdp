defmodule ExSDP.WebRTCTest do
  use ExUnit.Case

  test "Parses SDP with attributes specific for WebRTC" do
    {:ok, parsed} =
      """
      v=0
      o=- 10697771362128785113 0 IN IP4 127.0.0.1
      s=-
      t=0 0
      a=ice-lite
      a=group:BUNDLE 0 1
      m=audio 9 UDP/TLS/RTP/SAVPF 120
      c=IN IP4 0.0.0.0
      a=sendrecv
      a=ice-ufrag:UEqK
      a=ice-pwd:ZZ5rsux1D15c7j4nKrhYEH
      a=ice-options:trickle
      a=fingerprint:sha-256 92:35:B0:F7:B5:98:6D:E3:B8:7C:EA:03:84:7D:16:B6:D8:01:4C:48:61:9A:EF:DE:83:31:A0:2A:09:A9:47:92
      a=setup:actpass
      a=mid:0
      a=msid:699c4cc3-91bf-40e0-a664-a96ee2d103c2 95315dd8-13a2-4e3c-952a-c57042a75dc2
      a=rtcp-mux
      a=rtpmap:120 OPUS/48000/2
      a=fmtp:120 useinbandfec=1
      a=ssrc:990927281 cname:media0
      m=video 9 UDP/TLS/RTP/SAVPF 96
      c=IN IP4 0.0.0.0
      a=ice-ufrag:UEqK
      a=ice-pwd:ZZ5rsux1D15c7j4nKrhYEH
      a=ice-options:trickle
      a=fingerprint:sha-256 92:35:B0:F7:B5:98:6D:E3:B8:7C:EA:03:84:7D:16:B6:D8:01:4C:48:61:9A:EF:DE:83:31:A0:2A:09:A9:47:92
      a=setup:actpass
      a=mid:1
      a=msid:699c4cc3-91bf-40e0-a664-a96ee2d103c2 9f80e638-16f2-4120-81b3-8b4290df3ab6
      a=rtcp-mux
      a=rtcp-rsize
      a=rtpmap:96 H264/90000
      a=fmtp:96 profile-level-id=42e01f;level-asymmetry-allowed=1;packetization-mode=1
      a=ssrc:50301058 cname:media1
      """
      |> String.replace("\n", "\r\n")
      |> ExSDP.parse()

    assert parsed == %ExSDP{
             attributes: [
               %ExSDP.Attribute.Group{semantics: "BUNDLE", mids: ["0", "1"]},
               :ice_lite
             ],
             media: [
               %ExSDP.Media{
                 attributes: [
                   :sendrecv,
                   {:ice_ufrag, "UEqK"},
                   {:ice_pwd, "ZZ5rsux1D15c7j4nKrhYEH"},
                   {:ice_options, ["trickle"]},
                   {:fingerprint,
                    {:sha256,
                     "92:35:B0:F7:B5:98:6D:E3:B8:7C:EA:03:84:7D:16:B6:D8:01:4C:48:61:9A:EF:DE:83:31:A0:2A:09:A9:47:92"}},
                   {:setup, :actpass},
                   {:mid, "0"},
                   %ExSDP.Attribute.MSID{
                     app_data: "95315dd8-13a2-4e3c-952a-c57042a75dc2",
                     id: "699c4cc3-91bf-40e0-a664-a96ee2d103c2"
                   },
                   :rtcp_mux,
                   %ExSDP.Attribute.RTPMapping{
                     clock_rate: 48_000,
                     encoding: "OPUS",
                     params: 2,
                     payload_type: 120
                   },
                   %ExSDP.Attribute.FMTP{pt: 120, useinbandfec: true},
                   %ExSDP.Attribute.SSRC{attribute: "cname", id: 990_927_281, value: "media0"}
                 ],
                 connection_data: [
                   %ExSDP.ConnectionData{address: {0, 0, 0, 0}, network_type: "IN"}
                 ],
                 fmt: [120],
                 port: 9,
                 port_count: 1,
                 protocol: "UDP/TLS/RTP/SAVPF",
                 type: :audio
               },
               %ExSDP.Media{
                 attributes: [
                   {:ice_ufrag, "UEqK"},
                   {:ice_pwd, "ZZ5rsux1D15c7j4nKrhYEH"},
                   {:ice_options, ["trickle"]},
                   {:fingerprint,
                    {:sha256,
                     "92:35:B0:F7:B5:98:6D:E3:B8:7C:EA:03:84:7D:16:B6:D8:01:4C:48:61:9A:EF:DE:83:31:A0:2A:09:A9:47:92"}},
                   {:setup, :actpass},
                   {:mid, "1"},
                   %ExSDP.Attribute.MSID{
                     app_data: "9f80e638-16f2-4120-81b3-8b4290df3ab6",
                     id: "699c4cc3-91bf-40e0-a664-a96ee2d103c2"
                   },
                   :rtcp_mux,
                   :rtcp_rsize,
                   %ExSDP.Attribute.RTPMapping{
                     clock_rate: 90_000,
                     encoding: "H264",
                     payload_type: 96
                   },
                   %ExSDP.Attribute.FMTP{
                     level_asymmetry_allowed: true,
                     packetization_mode: 1,
                     profile_level_id: 4_382_751,
                     pt: 96
                   },
                   %ExSDP.Attribute.SSRC{attribute: "cname", id: 50_301_058, value: "media1"}
                 ],
                 connection_data: [
                   %ExSDP.ConnectionData{address: {0, 0, 0, 0}, network_type: "IN"}
                 ],
                 fmt: [96],
                 port: 9,
                 port_count: 1,
                 protocol: "UDP/TLS/RTP/SAVPF",
                 type: :video
               }
             ],
             origin: %ExSDP.Origin{
               address: {127, 0, 0, 1},
               network_type: "IN",
               session_id: 10_697_771_362_128_785_113,
               session_version: 0
             },
             session_name: "-",
             timing: %ExSDP.Timing{start_time: 0, stop_time: 0},
             version: 0
           }
  end

  test "SDP with rtx and FID ssrc-group" do
    # SDP from Chrome, sent to Jitsi Meet with some of the encodings dropped
    sdp =
      """
      v=0
      o=- 3308242971272944906 2 IN IP4 127.0.0.1
      s=-
      t=0 0
      a=group:BUNDLE 0 1
      a=extmap-allow-mixed
      m=audio 9 UDP/TLS/RTP/SAVPF 111 63
      c=IN IP4 0.0.0.0
      a=ice-ufrag:zPE+
      a=ice-pwd:5uuTJKfWTxRYyERtPlvUeKsU
      a=ice-options:trickle
      a=fingerprint:sha-256 99:0A:CB:FF:C2:0E:B0:C5:28:66:1B:69:AD:D6:60:A3:FA:E6:19:87:79:E9:85:9B:EA:69:70:A8:82:4A:AC:05
      a=setup:actpass
      a=mid:0
      a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
      a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
      a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
      a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
      a=sendrecv
      a=msid:040ad92b-583f-44d2-93e8-de4d40ac49ec 730bdafa-23f3-4111-85b4-757a666d462c
      a=rtcp-mux
      a=rtpmap:111 opus/48000/2
      a=rtcp-fb:111 transport-cc
      a=fmtp:111 minptime=10;useinbandfec=1
      a=rtpmap:63 red/48000/2
      a=fmtp:63 111/111
      a=ssrc:10136459 cname:fsp95kJbiDm+35qA
      a=ssrc:10136459 msid:040ad92b-583f-44d2-93e8-de4d40ac49ec 730bdafa-23f3-4111-85b4-757a666d462c
      m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101
      c=IN IP4 0.0.0.0
      a=ice-ufrag:zPE+
      a=ice-pwd:5uuTJKfWTxRYyERtPlvUeKsU
      a=ice-options:trickle
      a=fingerprint:sha-256 99:0A:CB:FF:C2:0E:B0:C5:28:66:1B:69:AD:D6:60:A3:FA:E6:19:87:79:E9:85:9B:EA:69:70:A8:82:4A:AC:05
      a=setup:actpass
      a=mid:1
      a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
      a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
      a=extmap:10 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
      a=extmap:11 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
      a=sendrecv
      a=msid:b5f40727-fa04-44db-9f4c-35c5fe8f2c3a a68d0021-2492-4f05-a211-e6b9b19c57ff
      a=rtcp-mux
      a=rtcp-rsize
      a=rtpmap:96 VP8/90000
      a=rtcp-fb:96 goog-remb
      a=rtcp-fb:96 transport-cc
      a=rtcp-fb:96 ccm fir
      a=rtcp-fb:96 nack
      a=rtcp-fb:96 nack pli
      a=rtpmap:97 rtx/90000
      a=fmtp:97 apt=96
      a=rtpmap:98 VP9/90000
      a=rtcp-fb:98 goog-remb
      a=rtcp-fb:98 transport-cc
      a=rtcp-fb:98 ccm fir
      a=rtcp-fb:98 nack
      a=rtcp-fb:98 nack pli
      a=fmtp:98 profile-id=0
      a=rtpmap:99 rtx/90000
      a=fmtp:99 apt=98
      a=rtpmap:100 AV1/90000
      a=rtcp-fb:100 goog-remb
      a=rtcp-fb:100 transport-cc
      a=rtcp-fb:100 ccm fir
      a=rtcp-fb:100 nack
      a=rtcp-fb:100 nack pli
      a=rtpmap:101 AV1/90000
      a=rtcp-fb:101 goog-remb
      a=rtcp-fb:101 transport-cc
      a=rtcp-fb:101 ccm fir
      a=rtcp-fb:101 nack
      a=rtcp-fb:101 nack pli
      a=fmtp:101 profile=1
      a=ssrc-group:FID 1984225447 2555509203
      a=ssrc:1984225447 cname:fsp95kJbiDm+35qA
      a=ssrc:1984225447 msid:b5f40727-fa04-44db-9f4c-35c5fe8f2c3a a68d0021-2492-4f05-a211-e6b9b19c57ff
      a=ssrc:2555509203 cname:fsp95kJbiDm+35qA
      a=ssrc:2555509203 msid:b5f40727-fa04-44db-9f4c-35c5fe8f2c3a a68d0021-2492-4f05-a211-e6b9b19c57ff
      """
      |> String.replace("\n", "\r\n")

    assert {:ok, parsed} = ExSDP.parse(sdp)

    assert %ExSDP{attributes: attributes, media: [audio, video]} = parsed

    assert %ExSDP.Attribute.Group{mids: ["0", "1"], semantics: "BUNDLE"} in attributes
    assert :extmap_allow_mixed in attributes

    assert %ExSDP.Attribute.RTCPFeedback{pt: 111, feedback_type: :twcc} in audio.attributes
    assert %ExSDP.Attribute.FMTP{pt: 63, redundant_payloads: [111]} in audio.attributes

    assert %ExSDP.Attribute.RTCPFeedback{pt: 96, feedback_type: :remb} in video.attributes
    assert %ExSDP.Attribute.RTCPFeedback{pt: 96, feedback_type: :twcc} in video.attributes
    assert %ExSDP.Attribute.RTCPFeedback{pt: 96, feedback_type: :fir} in video.attributes
    assert %ExSDP.Attribute.RTCPFeedback{pt: 96, feedback_type: :nack} in video.attributes
    assert %ExSDP.Attribute.RTCPFeedback{pt: 96, feedback_type: :pli} in video.attributes
    assert %ExSDP.Attribute.FMTP{pt: 97, apt: 96} in video.attributes

    assert %ExSDP.Attribute.RTCPFeedback{pt: 98, feedback_type: :pli} in video.attributes
    assert %ExSDP.Attribute.FMTP{pt: 99, apt: 98} in video.attributes

    assert %ExSDP.Attribute.FMTP{pt: 101, profile: 1} in video.attributes

    assert video.attributes |> Enum.at(-5) == %ExSDP.Attribute.SSRCGroup{
             semantics: "FID",
             ssrcs: [1_984_225_447, 2_555_509_203]
           }
  end
end

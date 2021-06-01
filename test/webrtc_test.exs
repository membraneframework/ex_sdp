defmodule ExSDP.WebRTCTest do
  use ExUnit.Case

  test "Parses SDP with attributes specific for WebRTC" do
    {:ok, parsed} =
      """
      v=0
      o=- 10697771362128785113 0 IN IP4 127.0.0.1
      s=-
      t=0 0
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
             attributes: [%ExSDP.Attribute.Group{semantics: "BUNDLE", mids: ["0", "1"]}],
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
end

defmodule Membrane.Protocol.SDP.RFCTest do
  @moduledoc """
  This test suit contains specs from RFC [4566](https://tools.ietf.org/html/rfc4566)
  and [4317](https://tools.ietf.org/html/rfc4317)
  that should be parsed by this parser.
  """
  use ExUnit.Case

  alias Membrane.Support.SpecHelper
  alias Membrane.Protocol.SDP

  describe "SDP parser processes SDP specs from RFC" do
    test "Parses single media spec with flag attributes" do
      assert {:ok, session_spec} =
               """
               v=0
               o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
               s=SDP Seminar
               i=A Seminar on the session description protocol
               u=http://www.example.com/seminars/sdp.pdf
               e=j.doe@example.com (Jane Doe)
               c=IN IP4 224.2.17.12/127
               t=2873397496 2873404696
               a=recvonly
               m=audio 49170 RTP/AVP 0
               m=video 51372 RTP/AVP 99
               a=rtpmap:99 h263-1998/90000
               """
               |> SpecHelper.from_binary()
               |> SDP.parse()

      assert session_spec == %Membrane.Protocol.SDP.Session{
               attributes: ["recvonly"],
               connection_information: [
                 %Membrane.Protocol.SDP.ConnectionInformation{
                   address: %Membrane.Protocol.SDP.ConnectionInformation.IP4{
                     ttl: 127,
                     value: {224, 2, 17, 12}
                   },
                   network_type: "IN"
                 }
               ],
               email: "j.doe@example.com (Jane Doe)",
               media: [
                 %Membrane.Protocol.SDP.Media{
                   attributes: [],
                   bandwidth: [],
                   connection_information: [
                     %Membrane.Protocol.SDP.ConnectionInformation{
                       address: %Membrane.Protocol.SDP.ConnectionInformation.IP4{
                         ttl: 127,
                         value: {224, 2, 17, 12}
                       },
                       network_type: "IN"
                     }
                   ],
                   fmt: "0",
                   ports: [49170],
                   protocol: "RTP/AVP",
                   type: "audio"
                 },
                 %Membrane.Protocol.SDP.Media{
                   attributes: ["rtpmap:99 h263-1998/90000"],
                   connection_information: [
                     %Membrane.Protocol.SDP.ConnectionInformation{
                       address: %Membrane.Protocol.SDP.ConnectionInformation.IP4{
                         ttl: 127,
                         value: {224, 2, 17, 12}
                       },
                       network_type: "IN"
                     }
                   ],
                   fmt: "99",
                   ports: [51372],
                   protocol: "RTP/AVP",
                   type: "video"
                 }
               ],
               origin: %Membrane.Protocol.SDP.Origin{
                 address_type: "IP4",
                 network_type: "IN",
                 session_id: "2890844526",
                 session_version: "2890842807",
                 unicast_address: {10, 47, 16, 5},
                 username: "jdoe"
               },
               session_information: "A Seminar on the session description protocol",
               session_name: "SDP Seminar",
               timing: %Membrane.Protocol.SDP.Timing{
                 start_time: 2_873_397_496,
                 stop_time: 2_873_404_696
               },
               uri: "http://www.example.com/seminars/sdp.pdf",
               version: "0"
             }
    end

    test "parses audio and video offer" do
      assert {:ok, result} =
               """
               v=0
               o=alice 2890844526 2890844526 IN IP4 host.atlanta.example.com
               s=
               c=IN IP4 host.atlanta.example.com
               t=0 0
               m=audio 49170 RTP/AVP 0 8 97
               a=rtpmap:0 PCMU/8000
               a=rtpmap:8 PCMA/8000
               a=rtpmap:97 iLBC/8000
               m=video 51372 RTP/AVP 31 32
               a=rtpmap:31 H261/90000
               a=rtpmap:32 MPV/90000
               """
               |> String.replace("\n", "\r\n")
               |> SDP.parse()

      assert %Membrane.Protocol.SDP.Session{
               attributes: [],
               bandwidth: [],
               connection_information: [
                 %Membrane.Protocol.SDP.ConnectionInformation{
                   address: "host.atlanta.example.com",
                   network_type: "IN"
                 }
               ],
               email: nil,
               encryption: nil,
               media: [
                 %Membrane.Protocol.SDP.Media{
                   attributes: ["rtpmap:0 PCMU/8000", "rtpmap:8 PCMA/8000", "rtpmap:97 iLBC/8000"],
                   bandwidth: [],
                   connection_information: [
                     %Membrane.Protocol.SDP.ConnectionInformation{
                       address: "host.atlanta.example.com",
                       network_type: "IN"
                     }
                   ],
                   encryption: nil,
                   fmt: "0 8 97",
                   ports: [49170],
                   protocol: "RTP/AVP",
                   title: nil,
                   type: "audio"
                 },
                 %Membrane.Protocol.SDP.Media{
                   attributes: ["rtpmap:31 H261/90000", "rtpmap:32 MPV/90000"],
                   bandwidth: [],
                   connection_information: [
                     %Membrane.Protocol.SDP.ConnectionInformation{
                       address: "host.atlanta.example.com",
                       network_type: "IN"
                     }
                   ],
                   encryption: nil,
                   fmt: "31 32",
                   ports: [51372],
                   protocol: "RTP/AVP",
                   title: nil,
                   type: "video"
                 }
               ],
               origin: %Membrane.Protocol.SDP.Origin{
                 address_type: "IP4",
                 network_type: "IN",
                 session_id: "2890844526",
                 session_version: "2890844526",
                 unicast_address: "host.atlanta.example.com",
                 username: "alice"
               },
               phone_number: nil,
               session_information: nil,
               session_name: "",
               time_repeats: [],
               time_zones_adjustments: [],
               timing: %Membrane.Protocol.SDP.Timing{start_time: 0, stop_time: 0},
               uri: nil,
               version: "0"
             } == result
    end

    test "parses audio and video answer" do
      assert {:ok, result} =
               """
               v=0
               o=bob 2808844564 2808844564 IN IP4 host.biloxi.example.com
               s=
               c=IN IP4 host.biloxi.example.com
               t=0 0
               m=audio 49174 RTP/AVP 0
               a=rtpmap:0 PCMU/8000
               m=video 49170 RTP/AVP 32
               a=rtpmap:32 MPV/90000
               """
               |> String.replace("\n", "\r\n")
               |> SDP.parse()

      assert %Membrane.Protocol.SDP.Session{
               attributes: [],
               bandwidth: [],
               connection_information: [
                 %Membrane.Protocol.SDP.ConnectionInformation{
                   address: "host.biloxi.example.com",
                   network_type: "IN"
                 }
               ],
               email: nil,
               encryption: nil,
               media: [
                 %Membrane.Protocol.SDP.Media{
                   attributes: ["rtpmap:0 PCMU/8000"],
                   bandwidth: [],
                   connection_information: [
                     %Membrane.Protocol.SDP.ConnectionInformation{
                       address: "host.biloxi.example.com",
                       network_type: "IN"
                     }
                   ],
                   encryption: nil,
                   fmt: "0",
                   ports: [49174],
                   protocol: "RTP/AVP",
                   title: nil,
                   type: "audio"
                 },
                 %Membrane.Protocol.SDP.Media{
                   attributes: ["rtpmap:32 MPV/90000"],
                   bandwidth: [],
                   connection_information: [
                     %Membrane.Protocol.SDP.ConnectionInformation{
                       address: "host.biloxi.example.com",
                       network_type: "IN"
                     }
                   ],
                   encryption: nil,
                   fmt: "32",
                   ports: [49170],
                   protocol: "RTP/AVP",
                   title: nil,
                   type: "video"
                 }
               ],
               origin: %Membrane.Protocol.SDP.Origin{
                 address_type: "IP4",
                 network_type: "IN",
                 session_id: "2808844564",
                 session_version: "2808844564",
                 unicast_address: "host.biloxi.example.com",
                 username: "bob"
               },
               phone_number: nil,
               session_information: nil,
               session_name: "",
               time_repeats: [],
               time_zones_adjustments: [],
               timing: %Membrane.Protocol.SDP.Timing{start_time: 0, stop_time: 0},
               uri: nil,
               version: "0"
             } = result
    end
  end
end

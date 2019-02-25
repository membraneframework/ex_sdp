defmodule Membrane.Protocol.SDP.RFCTest do
  @moduledoc """
  This test suit contains specs from RFC [4566](tools.ietf.org/html/rfc4566)
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
                   bandwidth: nil,
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
  end
end

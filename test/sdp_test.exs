defmodule Membrane.Protocol.SDPTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Membrane.Protocol.SDP

  alias Membrane.Protocol.SDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    RepeatTimes,
    Session,
    Timezone,
    Timing
  }

  @error_color_prefix "\e[31m"
  @back_to_normal "\e[0m"

  test "SDP parser parses long and complex session description" do
    assert {:ok, result} =
             """
             v=0
             o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
             s=Very fancy session name
             i=A Seminar on the session description protocol
             u=http://www.example.com/seminars/sdp.pdf
             e=j.doe@example.com (Jane Doe)
             p=111 111 111
             c=IN IP4 224.2.17.12/127
             b=YZ:256
             b=X-YZ:128
             t=2873397496 2873404696
             r=604800 3600 0 90000
             r=7d 1h 0 25h
             z=2882844526 -1h 2898848070 0
             k=clear:key
             a=recvonly
             a=key:value
             m=audio 49170 RTP/AVP 0
             i=Sample media title
             k=prompt
             m=video 51372 RTP/AVP 99
             a=rtpmap:99 h263-1998/90000
             """
             |> String.replace("\n", "\r\n")
             |> SDP.parse()

    assert result == %Session{
             attributes: [{"key", "value"}, :recvonly],
             bandwidth: [
               %Bandwidth{bandwidth: 128, type: "X-YZ"},
               %Bandwidth{bandwidth: 256, type: "YZ"}
             ],
             connection_data: %ConnectionData{
               address: %ConnectionData.IP4{
                 ttl: 127,
                 value: {224, 2, 17, 12}
               },
               network_type: "IN"
             },
             email: "j.doe@example.com (Jane Doe)",
             encryption: %Encryption{key: "key", method: :clear},
             media: [
               %Media{
                 attributes: [],
                 bandwidth: [
                   %Bandwidth{bandwidth: 128, type: "X-YZ"},
                   %Bandwidth{bandwidth: 256, type: "YZ"}
                 ],
                 connection_data: %ConnectionData{
                   address: %ConnectionData.IP4{
                     ttl: 127,
                     value: {224, 2, 17, 12}
                   },
                   network_type: "IN"
                 },
                 encryption: %Encryption{key: nil, method: :prompt},
                 fmt: [0],
                 ports: [49170],
                 protocol: "RTP/AVP",
                 title: "Sample media title",
                 type: "audio"
               },
               %Media{
                 attributes: [
                   {:rtpmap,
                    %Attribute.RTPMapping{
                      clock_rate: 90000,
                      encoding: "h263-1998",
                      params: [],
                      payload_type: 99
                    }}
                 ],
                 bandwidth: [
                   %Bandwidth{bandwidth: 128, type: "X-YZ"},
                   %Bandwidth{bandwidth: 256, type: "YZ"}
                 ],
                 connection_data: %ConnectionData{
                   address: %ConnectionData.IP4{
                     ttl: 127,
                     value: {224, 2, 17, 12}
                   },
                   network_type: "IN"
                 },
                 encryption: %Encryption{key: "key", method: :clear},
                 fmt: [99],
                 ports: [51372],
                 protocol: "RTP/AVP",
                 title: nil,
                 type: "video"
               }
             ],
             origin: %Origin{
               address: %ConnectionData{
                 network_type: "IN",
                 address: %ConnectionData.IP4{
                   value: {10, 47, 16, 5}
                 }
               },
               session_id: "2890844526",
               session_version: "2890842807",
               username: "jdoe"
             },
             phone_number: "111 111 111",
             session_information: "A Seminar on the session description protocol",
             session_name: "Very fancy session name",
             time_repeats: [
               %RepeatTimes{
                 active_duration: 3600,
                 offsets: [0, 90000],
                 repeat_interval: 604_800
               },
               %RepeatTimes{
                 active_duration: 3600,
                 offsets: [0, 90000],
                 repeat_interval: 604_800
               }
             ],
             time_zones_adjustments: [
               %Timezone{adjustment_time: 2_882_844_526, offset: "-1h"},
               %Membrane.Protocol.SDP.Timezone{adjustment_time: 2_898_848_070, offset: "0"}
             ],
             timing: %Timing{
               start_time: 2_873_397_496,
               stop_time: 2_873_404_696
             },
             uri: "http://www.example.com/seminars/sdp.pdf",
             version: "0"
           }
  end

  describe "Logger logs errors" do
    test "when parsing media" do
      logs =
        capture_log(fn ->
          assert {:error, _} =
                   """
                   m=video 51372 RTP/AVP 99
                   a=rtpmap:99 h263-1998/90000
                   c=invalid data
                   """
                   |> String.replace("\n", "\r\n")
                   |> SDP.parse()
        end)

      assert logs =~ """
             Error while parsing media:
             m=video 51372 RTP/AVP 99

             Attributes:
             a=rtpmap:99 h263-1998/90000
             c=invalid data

             with reason: invalid_connection_data
             """

      assert error_log?(logs)
    end

    test "when parsing non-media" do
      logs =
        capture_log(fn ->
          assert {:error, _} =
                   "o=jdoe 2890844526 2890842807 IN"
                   |> String.replace("\n", "\r\n")
                   |> SDP.parse()
        end)

      assert logs =~ """
             An error has occurred while parsing following SDP line:
             o=jdoe 2890844526 2890842807 IN
             with reason: invalid_origin
             """

      assert error_log?(logs)
    end
  end

  defp error_log?(logs) do
    String.starts_with?(logs, @error_color_prefix) && String.ends_with?(logs, @back_to_normal) &&
      String.contains?(logs, "[error]")
  end
end

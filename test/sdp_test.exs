defmodule ExSDPTest do
  use ExUnit.Case

  alias ExSDP

  alias ExSDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    RepeatTimes,
    Timezone,
    Timing
  }

  alias Timezone.Correction

  @input """
         v=0
         o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
         s=Very fancy session name
         i=A Seminar on the session description protocol
         u=http://www.example.com/seminars/sdp.pdf
         e=j.doe@example.com (Jane Doe)
         p=111 111 111
         c=IN IP4 224.2.17.12/127
         b=CT:256
         t=2873397496 2873404696
         r=604800 3600 0 90000
         r=7d 1h 0 25h
         z=2882844526 -1h 2898848070 2h
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

  @expected_output %ExSDP{
    attributes: [{"key", "value"}, :recvonly],
    bandwidth: [
      %Bandwidth{bandwidth: 256, type: :CT}
    ],
    connection_data: %ConnectionData{
      addresses: [
        %ConnectionData.IP4{
          ttl: 127,
          value: {224, 2, 17, 12}
        }
      ]
    },
    email: "j.doe@example.com (Jane Doe)",
    encryption: %Encryption{key: "key", method: :clear},
    media: [
      %Media{
        attributes: [],
        bandwidth: [
          %Bandwidth{bandwidth: 256, type: :CT}
        ],
        connection_data: %ConnectionData{
          addresses: [
            %ConnectionData.IP4{
              ttl: 127,
              value: {224, 2, 17, 12}
            }
          ]
        },
        encryption: %Encryption{key: nil, method: :prompt},
        fmt: [0],
        ports: [49_170],
        protocol: "RTP/AVP",
        title: "Sample media title",
        type: :audio
      },
      %Media{
        attributes: [
          %Attribute.RTPMapping{
            clock_rate: 90_000,
            encoding: "h263-1998",
            params: nil,
            payload_type: 99
          }
        ],
        bandwidth: [
          %Bandwidth{bandwidth: 256, type: :CT}
        ],
        connection_data: %ConnectionData{
          addresses: [
            %ConnectionData.IP4{
              ttl: 127,
              value: {224, 2, 17, 12}
            }
          ]
        },
        encryption: %Encryption{key: "key", method: :clear},
        fmt: [99],
        ports: [51_372],
        protocol: "RTP/AVP",
        title: nil,
        type: :video
      }
    ],
    origin: %Origin{
      address: %ConnectionData.IP4{
        value: {10, 47, 16, 5}
      },
      session_id: 2_890_844_526,
      session_version: 2_890_842_807,
      username: "jdoe"
    },
    phone_number: "111 111 111",
    session_information: "A Seminar on the session description protocol",
    session_name: "Very fancy session name",
    time_repeats: [
      %RepeatTimes{
        active_duration: 3600,
        offsets: [0, 90_000],
        repeat_interval: 604_800
      },
      %RepeatTimes{
        active_duration: 3600,
        offsets: [0, 90_000],
        repeat_interval: 604_800
      }
    ],
    time_zones_adjustments: %Timezone{
      corrections: [
        %Correction{adjustment_time: 2_882_844_526, offset: -1},
        %Correction{adjustment_time: 2_898_848_070, offset: 2}
      ]
    },
    timing: %Timing{
      start_time: 2_873_397_496,
      stop_time: 2_873_404_696
    },
    uri: "http://www.example.com/seminars/sdp.pdf",
    version: 0
  }

  describe "Parser parse/1" do
    test "parses long and complex session description" do
      assert {:ok, result} = ExSDP.parse(@input)
      assert result == @expected_output
    end

    test "returns an error with line that crashed parser" do
      input =
        """
        v=0
        o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
        s=Very fancy session name
        i=A Seminar on the session description protocol
        u=http://www.example.com/seminars/sdp.pdf
        e=j.doe@example.com (Jane Doe)
        p=111 111 111
        c=IN IP4 224.2.17.12/127
        b=X-YZ:256
        """
        |> String.replace("\n", "\r\n")

      assert {:error, {:invalid_bandwidth, "b=X-YZ:256"}} == assert(ExSDP.parse(input))
    end
  end

  describe "Parser parse!/1" do
    test "returns SDP spec when parsing valid input" do
      assert @expected_output == ExSDP.parse!(@input)
    end

    test "raises an error when parsing invalid media" do
      expected_message = """
      Error while parsing media:
      m=video 51372 RTP/AVP 99

      Attributes:
      a=rtpmap:99 h263-1998/90000
      c=invalid data

      with reason: invalid_connection_data
      """

      assert_raise RuntimeError, expected_message, fn ->
        """
        m=video 51372 RTP/AVP 99
        a=rtpmap:99 h263-1998/90000
        c=invalid data
        """
        |> String.replace("\n", "\r\n")
        |> ExSDP.parse!()
      end
    end

    test "raises an error when parsing invalid non media attribute" do
      expected = """
      An error has occurred while parsing following SDP line:
      o=jdoe 2890844526 2890842807 IN
      with reason: invalid_connection_data
      """

      assert_raise RuntimeError, expected, fn ->
        "o=jdoe 2890844526 2890842807 IN"
        |> String.replace("\n", "\r\n")
        |> ExSDP.parse!()
      end
    end
  end
end

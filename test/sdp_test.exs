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
    connection_data: %ConnectionData{address: {224, 2, 17, 12}, ttl: 127},
    email: "j.doe@example.com (Jane Doe)",
    encryption: %Encryption{key: "key", method: :clear},
    media: [
      %Media{
        attributes: [],
        bandwidth: [
          %Bandwidth{bandwidth: 256, type: :CT}
        ],
        connection_data: %ConnectionData{ttl: 127, address: {224, 2, 17, 12}},
        encryption: %Encryption{key: nil, method: :prompt},
        fmt: [0],
        port: 49_170,
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
        connection_data: %ConnectionData{ttl: 127, address: {224, 2, 17, 12}},
        encryption: %Encryption{key: "key", method: :clear},
        fmt: [99],
        port: 51_372,
        protocol: "RTP/AVP",
        title: nil,
        type: :video
      }
    ],
    origin: %Origin{
      address: {10, 47, 16, 5},
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
        b=AS:fast
        """
        |> String.replace("\n", "\r\n")

      assert {:error, {:invalid_bandwidth, "b=AS:fast"}} == assert(ExSDP.parse(input))
    end

    test "ignores a bandwidth field with an unknown modifier" do
      input = "v=0\r\no=- 0 0 IN IP4 127.0.0.1\r\ns=-\r\nb=X-YZ:256\r\nb=AS:64\r\nt=0 0\r\n"

      assert {:ok, %ExSDP{bandwidth: [%ExSDP.Bandwidth{type: :AS, bandwidth: 64}]}} =
               ExSDP.parse(input)
    end

    test "returns an error on invalid line" do
      input =
        """
        v=0
        o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
        l=invalid line
        s=Very fancy session name
        """
        |> String.replace("\n", "\r\n")

      assert {:error, {:invalid_line, "l=invalid line"}} = ExSDP.parse(input)
    end
  end

  describe "Parser parse/1 on malformed input returns an error instead of raising" do
    defp parse_session(lines) do
      (["v=0", "o=- 1 1 IN IP4 10.0.0.1", "s=x", "t=0 0"] ++ lines)
      |> Enum.map_join(&(&1 <> "\r\n"))
      |> ExSDP.parse()
    end

    test "when the version is not a number" do
      assert {:error, {:invalid_version, "v=zero"}} = ExSDP.parse("v=zero\r\ns=x\r\n")
    end

    test "when the origin carries identifiers that are not numbers" do
      assert {:error, {:invalid_session_id, "o=- abc 1 IN IP4 10.0.0.1"}} =
               ExSDP.parse("v=0\r\no=- abc 1 IN IP4 10.0.0.1\r\ns=x\r\n")

      assert {:error, {:invalid_session_version, "o=- 1 1.5 IN IP4 10.0.0.1"}} =
               ExSDP.parse("v=0\r\no=- 1 1.5 IN IP4 10.0.0.1\r\ns=x\r\n")
    end

    test "when a line that belongs to the session section appears in a media section" do
      assert {:error, {:invalid_line, "m=video 0 RTP/AVP 96"}} =
               parse_session(["m=video 0 RTP/AVP 96", "a=rtpmap:96 H264/90000", "t=0 0"])
    end

    test "when a media section holds a line of an unknown type" do
      assert {:error, {:invalid_line, "m=video 0 RTP/AVP 96"}} =
               parse_session(["m=video 0 RTP/AVP 96", "y=0100000001"])
    end

    test "when the number of channels in rtpmap is not a number" do
      assert {:error, {:invalid_rtpmap, "m=audio 0 RTP/AVP 97"}} =
               parse_session(["m=audio 0 RTP/AVP 97", "a=rtpmap:97 PCMU/8000/x"])
    end

    test "when rtpmap appears at the session level" do
      assert {:ok,
              %ExSDP{attributes: [%ExSDP.Attribute.RTPMapping{encoding: "H264", params: nil}]}} =
               parse_session(["a=rtpmap:96 H264/90000"])
    end

    test "when the port of a media line is not a number or a number and a count" do
      for port <- ["0-1", "0abc", "0/abc", "0/0", "0/"] do
        assert {:error, {reason, "m=video " <> _rest}} =
                 parse_session(["m=video #{port} RTP/AVP 96"])

        assert reason in [:invalid_port_number, :invalid_port_count]
      end
    end

    test "when an address is not valid text" do
      assert {:error, {:invalid_address, "c=IN IP4 " <> _rest}} =
               ExSDP.parse("v=0\r\nc=IN IP4 " <> <<0xFF, 0xFE>> <> "\r\n")

      assert {:error, {:invalid_address, "o=- 1 1 IN IP4 " <> _rest}} =
               ExSDP.parse("v=0\r\no=- 1 1 IN IP4 " <> <<0xFF, 0xFE>> <> "\r\n")
    end

    test "when a repeat time in the compact form is followed by something that is not a time" do
      assert {:error, {_reason, "r=7d 1h 0 25h x"}} =
               ExSDP.parse("v=0\r\nt=0 0\r\nr=7d 1h 0 25h x\r\n")
    end

    test "when an attribute that takes a value comes without one" do
      for attribute <-
            ~w(rtpmap fmtp framerate ptime fingerprint ssrc msid extmap rtcp-fb ice-options) do
        assert {:error, {:missing_attribute_value, "m=video 0 RTP/AVP 96"}} =
                 parse_session(["m=video 0 RTP/AVP 96", "a=#{attribute}"])
      end
    end
  end

  describe "Parser parse/1 skips empty lines" do
    test "in the session section" do
      input = "v=0\r\n\r\no=- 1 1 IN IP4 10.0.0.1\r\ns=x\r\n\r\nt=0 0\r\nm=video 0 RTP/AVP 96\r\n"

      assert {:ok, %ExSDP{session_name: "x", timing: %ExSDP.Timing{}, media: [_video]}} =
               ExSDP.parse(input)
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

      with reason: too_few_fields
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
      with reason: too_few_fields
      """

      assert_raise RuntimeError, expected, fn ->
        "o=jdoe 2890844526 2890842807 IN"
        |> String.replace("\n", "\r\n")
        |> ExSDP.parse!()
      end
    end
  end

  describe "Utils functions" do
    test "gets and deletes attribute by atom, binary or module" do
      sdp =
        ExSDP.new()
        |> ExSDP.add_attribute({"key", "value"})
        |> ExSDP.add_attribute(:recvonly)
        |> ExSDP.add_attribute(%ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [0, 1, 2]})

      assert :recvonly == ExSDP.get_attribute(sdp, :recvonly)
      assert {"key", "value"} == ExSDP.get_attribute(sdp, "key")

      assert %ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [0, 1, 2]} ==
               ExSDP.get_attribute(sdp, ExSDP.Attribute.Group)

      assert %ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [0, 1, 2]} ==
               ExSDP.get_attribute(sdp, :group)

      assert nil == ExSDP.get_attribute(sdp, :non_existing_atom)
      assert nil == ExSDP.get_attribute(sdp, ExSDP.Attribute.NonExistingModule)
      assert nil == ExSDP.get_attribute(sdp, "non_existing_string")

      assert [:recvonly, %ExSDP.Attribute.Group{}] = ExSDP.delete_attribute(sdp, "key").attributes

      assert [{"key", "value"}, %ExSDP.Attribute.Group{}] =
               ExSDP.delete_attribute(sdp, :recvonly).attributes

      assert [{"key", "value"}, :recvonly] =
               ExSDP.delete_attribute(sdp, ExSDP.Attribute.Group).attributes

      assert [] =
               ExSDP.delete_attributes(sdp, ["key", :recvonly, ExSDP.Attribute.Group]).attributes
    end

    test "gets multiple attributes by module" do
      sdp =
        ExSDP.new()
        |> ExSDP.add_attribute(%ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [0, 1, 2]})
        |> ExSDP.add_attribute(%ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [3, 4, 5]})

      assert [
               %ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [0, 1, 2]},
               %ExSDP.Attribute.Group{semantics: "BUNDLE", mids: [3, 4, 5]}
             ] ==
               ExSDP.get_attributes(sdp, ExSDP.Attribute.Group)
    end
  end
end

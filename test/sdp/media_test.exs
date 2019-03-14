defmodule Membrane.Protocol.SDP.MediaTest do
  use ExUnit.Case
  use Bunch

  alias Membrane.Protocol.SDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
    Session,
    Timing
  }

  describe "Media parser" do
    test "processes valid media description" do
      assert {:ok, media} =
               "video 49170 RTP/AVP 31"
               |> Media.parse()

      assert %Media{
               fmt: [31],
               ports: [49_170],
               protocol: "RTP/AVP",
               type: "video"
             } = media
    end

    test "processes valid media description with multiple ports" do
      assert {:ok, media} =
               "video 49170/2 RTP/AVP 31"
               |> Media.parse()

      assert %Media{
               fmt: [31],
               ports: [49_170, 49_172],
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

      parsed_attributes = [
        rtpmap: %Attribute.RTPMapping{
          clock_rate: 8000,
          encoding: "L8",
          params: [],
          payload_type: 96
        },
        rtpmap: %Attribute.RTPMapping{
          clock_rate: 8000,
          encoding: "L16",
          params: [],
          payload_type: 97
        },
        rtpmap: %Attribute.RTPMapping{
          clock_rate: 11_025,
          encoding: "L16",
          params: ["2"],
          payload_type: 98
        }
      ]

      {:ok, {[""], medium}} =
        media
        |> Media.parse()
        ~> ({:ok, medium} -> Media.parse_optional(attributes, medium))

      assert %Media{
               attributes: ^parsed_attributes,
               fmt: [96, 97, 98],
               ports: [49_230],
               protocol: "RTP/AVP",
               type: "m=audio"
             } = medium
    end
  end

  describe "Session property inheritance mechanism" do
    setup do
      {:ok, media} =
        "video 49170 RTP/AVP 31"
        |> Media.parse()

      bandwidth = [%Bandwidth{bandwidth: 128, type: "X-YZ"}]

      connection_data = [
        %ConnectionData{
          address: %ConnectionData.IP4{
            ttl: 127,
            value: {224, 2, 17, 12}
          },
          network_type: "IN"
        }
      ]

      encryption = %Encryption{method: :clear}

      session = %Session{
        connection_data: connection_data,
        origin: %Origin{
          session_id: "2890844526",
          address: %ConnectionData{
            network_type: "IN",
            address: %ConnectionData.IP4{
              value: {10, 47, 16, 5}
            }
          }
        },
        timing: %Timing{
          start_time: 2_873_397_496,
          stop_time: 2_873_404_696
        },
        encryption: encryption,
        bandwidth: bandwidth,
        session_name: "123",
        version: "0"
      }

      [
        session: session,
        encryption: encryption,
        connection_data: connection_data,
        bandwidth: bandwidth,
        media: media
      ]
    end

    test "media inherits session properties", %{
      session: session,
      encryption: encryption,
      connection_data: connection_data,
      bandwidth: bandwidth,
      media: media
    } do
      assert %Media{
               bandwidth: ^bandwidth,
               connection_data: ^connection_data,
               encryption: ^encryption
             } = Media.apply_session(media, session)
    end

    test "media optional parser overrides inherited values", %{
      session: session,
      media: media
    } do
      options =
        """
        b=YZ:128
        c=IN IP4 144.2.17.12/220
        k=prompt
        """
        |> String.split("\n")

      assert %Media{
               bandwidth: [%Bandwidth{bandwidth: 128, type: "YZ"}],
               connection_data: [
                 %ConnectionData.IP4{
                   ttl: 220,
                   value: {144, 2, 17, 12}
                 }
               ],
               encryption: %Encryption{key: nil, method: :prompt}
             } =
               options
               |> Media.parse_optional(media)
               ~> ({:ok, {_, medium}} -> Media.apply_session(medium, session))
    end
  end

  describe "FMT parser" do
    test "parses FMT RTP/AVP mapping" do
      assert {:ok, media} = Media.parse("audio 49170 RTP/AVP 0 98 99")
      assert %Media{fmt: [0, 98, 99], protocol: "RTP/AVP"} = media
    end

    test "parses non RTP/AVP FMT" do
      assert {:ok, media} = Media.parse("audio 49170 NON/AVP 0 98 99")
      assert %Media{fmt: "0 98 99", protocol: "NON/AVP"} = media
    end

    test "returns an error if one of payload types fails integer parsing" do
      assert {:error, :invalid_fmt} = Media.parse("audio 49170 RTP/AVP 0 9d8 99")
    end
  end
end

defmodule ExSDP.MediaTest do
  use ExUnit.Case
  use Bunch

  alias ExSDP

  alias ExSDP.{
    Attribute,
    Bandwidth,
    ConnectionData,
    Encryption,
    Media,
    Origin,
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
               type: :video
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
               type: :video
             } = media
    end

    test "processes media with attributes" do
      media = "audio 49230 RTP/AVP 96 97 98"

      attributes =
        """
        a=rtpmap:96 L8/8000
        a=rtpmap:97 L16/8000
        a=rtpmap:98 L16/11025/2
        """
        |> String.split("\n")

      parsed_attributes = [
        %Attribute.RTPMapping{
          clock_rate: 8000,
          encoding: "L8",
          params: 1,
          payload_type: 96
        },
        %Attribute.RTPMapping{
          clock_rate: 8000,
          encoding: "L16",
          params: 1,
          payload_type: 97
        },
        %Attribute.RTPMapping{
          clock_rate: 11_025,
          encoding: "L16",
          params: 2,
          payload_type: 98
        }
      ]

      {:ok, {[""], medium}} =
        media
        |> Media.parse()
        ~> ({:ok, medium} -> Media.parse_optional(attributes, medium))

      assert %Media{
               attributes: parsed_attributes,
               fmt: [96, 97, 98],
               ports: [49_230],
               protocol: "RTP/AVP",
               type: :audio
             } == medium
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
          addresses: [
            %ConnectionData.IP4{
              ttl: 127,
              value: {224, 2, 17, 12}
            }
          ]
        }
      ]

      encryption = %Encryption{method: :clear}

      session = %ExSDP{
        connection_data: connection_data,
        origin: %Origin{
          session_id: "2890844526",
          address: %ConnectionData{
            addresses: [
              %ConnectionData.IP4{
                value: {10, 47, 16, 5}
              }
            ]
          },
          username: "-",
          session_version: "2890842807"
        },
        timing: %Timing{
          start_time: 2_873_397_496,
          stop_time: 2_873_404_696
        },
        encryption: encryption,
        bandwidth: bandwidth,
        session_name: "123",
        version: 0
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
        b=AS:128
        c=IN IP4 144.2.17.12/220
        k=prompt
        """
        |> String.split("\n")

      result =
        options
        |> Media.parse_optional(media)
        ~> ({:ok, {_, medium}} -> Media.apply_session(medium, session))

      assert %Media{
               bandwidth: [%Bandwidth{bandwidth: 128, type: :AS}],
               connection_data: %ConnectionData{
                 addresses: [
                   %ConnectionData.IP4{
                     ttl: 220,
                     value: {144, 2, 17, 12}
                   }
                 ]
               },
               encryption: %Encryption{key: nil, method: :prompt}
             } = result
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

  describe "Media serializer" do
    test "serializes audio description" do
      media = %Media{type: :audio, protocol: "RTP/AVP", fmt: [0], ports: [49_170]}
      assert "#{media}" == "audio 49170 RTP/AVP 0"
    end

    test "serializes video description with an attribute" do
      # attribute = "rtpmap:99 h263-1998/90000"

      attribute = %Attribute.RTPMapping{
        clock_rate: 90_000,
        encoding: "h263-1998",
        params: nil,
        payload_type: 99
      }

      media = %Media{
        type: :video,
        protocol: "RTP/AVP",
        ports: [51_372],
        fmt: [99],
        attributes: [attribute]
      }

      assert "#{media}" == "video 51372 RTP/AVP 99\r\na=rtpmap:99 h263-1998/90000"
    end

    test "serializes media description with title, bandwidth and encryption description" do
      media = %Media{
        type: "type",
        ports: [12_345],
        title: "title",
        protocol: "some_protocol",
        fmt: [100],
        bandwidth: %Bandwidth{type: :CT, bandwidth: 64},
        encryption: %Encryption{method: :prompt}
      }

      assert "#{media}" == "type 12345 some_protocol 100\r\ni=title\r\nb=CT:64\r\nk=prompt"
    end

    test "serializes media with connection_data description" do
      addresses = [
        %ConnectionData.IP4{
          ttl: 127,
          value: {224, 2, 1, 1}
        },
        %ConnectionData.IP6{
          value: {15, 0, 0, 0, 0, 0, 0, 101}
        },
        %ConnectionData.FQDN{
          value: "https://some.uri.net"
        }
      ]

      serialized_addresses = [
        "IN IP4 224.2.1.1/127",
        "IN IP6 f::65",
        "IN IP4 https://some.uri.net"
      ]

      media = %Media{
        type: :video,
        protocol: "RTP/AVP",
        ports: [51_372],
        fmt: [99]
      }

      serialized_media = "video 51372 RTP/AVP 99"

      addresses
      |> Enum.zip(serialized_addresses)
      |> Enum.each(fn {address, serialized_address} ->
        media = %Media{media | connection_data: address}
        expected = "#{serialized_media}\r\nc=#{serialized_address}"
        assert "#{media}" == expected
      end)
    end
  end
end

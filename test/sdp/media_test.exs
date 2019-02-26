defmodule Membrane.Protocol.SDP.MediaTest do
  use ExUnit.Case
  use Bunch

  alias Membrane.Protocol.SDP.{Media, Encryption, Bandwidth, Session}

  describe "Media parser" do
    test "processes valid media description" do
      assert {:ok, media} =
               "video 49170 RTP/AVP 31"
               |> Media.parse()

      assert %Media{
               fmt: "31",
               ports: [49170],
               protocol: "RTP/AVP",
               type: "video"
             } = media
    end

    test "processes valid media description with multiple ports" do
      assert {:ok, media} =
               "video 49170/2 RTP/AVP 31"
               |> Media.parse()

      assert %Media{
               fmt: "31",
               ports: [49170, 49172],
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
        "rtpmap:96 L8/8000",
        "rtpmap:97 L16/8000",
        "rtpmap:98 L16/11025/2"
      ]

      {:ok, {[""], medium}} =
        media
        |> Media.parse()
        ~>> ({:ok, medium} -> Media.parse_optional(attributes, medium))

      assert %Media{
               attributes: ^parsed_attributes,
               fmt: "96 97 98",
               ports: [49230],
               protocol: "RTP/AVP",
               type: "m=audio"
             } = medium
    end
  end

  test "media inherits session properties" do
    bandwidth = %Bandwidth{bandwidth: "128", type: "X-YZ"}

    connection_information = [
      %Membrane.Protocol.SDP.ConnectionInformation{
        address: %Membrane.Protocol.SDP.ConnectionInformation.IP4{
          ttl: 127,
          value: {224, 2, 17, 12}
        },
        network_type: "IN"
      }
    ]

    encryption = %Encryption{method: "RSA"}

    session = %Session{
      connection_information: connection_information,
      origin: %Membrane.Protocol.SDP.Origin{
        address_type: "IP4",
        network_type: "IN",
        session_id: "2890844526",
        session_version: "2890842807",
        unicast_address: {10, 47, 16, 5},
        username: "jdoe"
      },
      timing: %Membrane.Protocol.SDP.Timing{
        start_time: 2_873_397_496,
        stop_time: 2_873_404_696
      },
      encryption: encryption,
      bandwidth: bandwidth,
      session_name: "123",
      version: "0"
    }

    assert {:ok, media} =
             "video 49170 RTP/AVP 31"
             |> Media.parse()

    assert %Media{
             bandwidth: bandwidth,
             connection_information: connection_information,
             encryption: encryption
           } = Media.apply_session(media, session)
  end

  describe "Session property inheritance mechanism" do
    setup do
      {:ok, media} =
        "video 49170 RTP/AVP 31"
        |> Media.parse()

      bandwidth = [%Bandwidth{bandwidth: "128", type: "X-YZ"}]

      connection_information = [
        %Membrane.Protocol.SDP.ConnectionInformation{
          address: %Membrane.Protocol.SDP.ConnectionInformation.IP4{
            ttl: 127,
            value: {224, 2, 17, 12}
          },
          network_type: "IN"
        }
      ]

      encryption = %Encryption{method: "RSA"}

      session = %Session{
        connection_information: connection_information,
        origin: %Membrane.Protocol.SDP.Origin{
          address_type: "IP4",
          network_type: "IN",
          session_id: "2890844526",
          session_version: "2890842807",
          unicast_address: {10, 47, 16, 5},
          username: "jdoe"
        },
        timing: %Membrane.Protocol.SDP.Timing{
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
        connection_information: connection_information,
        bandwidth: bandwidth,
        media: media
      ]
    end

    test "media inherits session properties", %{
      session: session,
      encryption: encryption,
      connection_information: connection_information,
      bandwidth: bandwidth,
      media: media
    } do
      assert %Media{
               bandwidth: ^bandwidth,
               connection_information: ^connection_information,
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

      assert %Membrane.Protocol.SDP.Media{
               bandwidth: [%Membrane.Protocol.SDP.Bandwidth{bandwidth: "128", type: "YZ"}],
               connection_information: [
                 %Membrane.Protocol.SDP.ConnectionInformation{
                   address: %Membrane.Protocol.SDP.ConnectionInformation.IP4{
                     ttl: 220,
                     value: {144, 2, 17, 12}
                   },
                   network_type: "IN"
                 }
               ],
               encryption: %Membrane.Protocol.SDP.Encryption{key: nil, method: "prompt"}
             } =
               options
               |> Media.parse_optional(media)
               ~>> ({:ok, {_, medium}} -> Media.apply_session(medium, session))
    end
  end
end

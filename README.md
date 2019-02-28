# Membrane Protocol SDP

Parser for Session Description Protocol

## Installation

The package can be installed by adding `membrane_protocol_sdp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:membrane_sdp, "~> 0.1.0"}
  ]
end
```

The docs can be found at [https://hexdocs.pm/membrane_sdp](https://hexdocs.pm/membrane_sdp).

## Usage

Parser parses string with `\r\n` terminated lines.

```elixir
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
k=rsa:key
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

# =>

%Session{
  attributes: [{"key", "value"}, "recvonly"],
  bandwidth: [
    %Bandwidth{bandwidth: "128", type: "X-YZ"},
    %Bandwidth{bandwidth: "256", type: "YZ"}
  ],
  connection_information: %ConnectionInformation{
    address: %ConnectionInformation.IP4{
      ttl: 127,
      value: {224, 2, 17, 12}
    },
    network_type: "IN"
  },
  email: "j.doe@example.com (Jane Doe)",
  encryption: "rsa:key",
  media: [
    %Media{
      attributes: [],
      bandwidth: [
        %Bandwidth{bandwidth: "128", type: "X-YZ"},
        %Bandwidth{bandwidth: "256", type: "YZ"}
      ],
      connection_information: %ConnectionInformation{
        address: %ConnectionInformation.IP4{
          ttl: 127,
          value: {224, 2, 17, 12}
        },
        network_type: "IN"
      },
      encryption: %Encryption{key: nil, method: "prompt"},
      fmt: "0",
      ports: [49170],
      protocol: "RTP/AVP",
      title: "Sample media title",
      type: "audio"
    },
    %Media{
      attributes: ["rtpmap:99 h263-1998/90000"],
      bandwidth: [
        %Bandwidth{bandwidth: "128", type: "X-YZ"},
        %Bandwidth{bandwidth: "256", type: "YZ"}
      ],
      connection_information: %ConnectionInformation{
        address: %ConnectionInformation.IP4{
          ttl: 127,
          value: {224, 2, 17, 12}
        },
        network_type: "IN"
      },
      encryption: "rsa:key",
      fmt: "99",
      ports: [51372],
      protocol: "RTP/AVP",
      title: nil,
      type: "video"
    }
  ],
  origin: %Origin{
    address_type: "IP4",
    network_type: "IN",
    session_id: "2890844526",
    session_version: "2890842807",
    unicast_address: {10, 47, 16, 5},
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

```
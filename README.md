# Membrane Protocol SDP

Parser for Session Description Protocol. Based on [RFC4566](https://tools.ietf.org/html/rfc4566)

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

Parser parses string with `\r\n` terminated lines. (although it will also accept records terminated with
a single newline character)

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
b=AS:256
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
|> Membrane.Protocol.SDP.parse()

# =>
{:ok,
 %Membrane.Protocol.SDP.Session{
   attributes: [{"key", "value"}, :recvonly],
   bandwidth: [%Membrane.Protocol.SDP.Bandwidth{bandwidth: 256, type: :AS}],
   connection_data: %Membrane.Protocol.SDP.ConnectionData.IP4{
     ttl: 127,
     value: {224, 2, 17, 12}
   },
   email: "j.doe@example.com (Jane Doe)",
   encryption: %Membrane.Protocol.SDP.Encryption{key: "key", method: :clear},
   media: [
     %Membrane.Protocol.SDP.Media{
       attributes: [],
       bandwidth: [%Membrane.Protocol.SDP.Bandwidth{bandwidth: 256, type: :AS}],
       connection_data: %Membrane.Protocol.SDP.ConnectionData.IP4{
         ttl: 127,
         value: {224, 2, 17, 12}
       },
       encryption: %Membrane.Protocol.SDP.Encryption{key: nil, method: :prompt},
       fmt: [0],
       ports: [49170],
       protocol: "RTP/AVP",
       title: "Sample media title",
       type: :audio
     },
     %Membrane.Protocol.SDP.Media{
       attributes: [
         rtpmap: %Membrane.Protocol.SDP.Attribute.RTPMapping{
           clock_rate: 90000,
           encoding: "h263-1998",
           params: [],
           payload_type: 99
         }
       ],
       bandwidth: [%Membrane.Protocol.SDP.Bandwidth{bandwidth: 256, type: :AS}],
       connection_data: %Membrane.Protocol.SDP.ConnectionData.IP4{
         ttl: 127,
         value: {224, 2, 17, 12}
       },
       encryption: %Membrane.Protocol.SDP.Encryption{key: "key", method: :clear},
       fmt: [99],
       ports: [51372],
       protocol: "RTP/AVP",
       title: nil,
       type: :video
     }
   ],
   origin: %Membrane.Protocol.SDP.Origin{
     address: %Membrane.Protocol.SDP.ConnectionData.IP4{
       ttl: nil,
       value: {10, 47, 16, 5}
     },
     session_id: "2890844526",
     session_version: "2890842807",
     username: "jdoe"
   },
   phone_number: "111 111 111",
   session_information: "A Seminar on the session description protocol",
   session_name: "Very fancy session name",
   time_repeats: [
     %Membrane.Protocol.SDP.RepeatTimes{
       active_duration: 3600,
       offsets: [0, 90000],
       repeat_interval: 604800
     },
     %Membrane.Protocol.SDP.RepeatTimes{
       active_duration: 3600,
       offsets: [0, 90000],
       repeat_interval: 604800
     }
   ],
   time_zones_adjustments: [
     %Membrane.Protocol.SDP.Timezone{adjustment_time: 2882844526, offset: -1},
     %Membrane.Protocol.SDP.Timezone{adjustment_time: 2898848070, offset: 0}
   ],
   timing: %Membrane.Protocol.SDP.Timing{
     start_time: 2873397496,
     stop_time: 2873404696
   },
   uri: "http://www.example.com/seminars/sdp.pdf",
   version: "0"
 }}

```
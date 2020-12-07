# ExSDP

[![Hex.pm](https://img.shields.io/hexpm/v/ex_sdp.svg)](https://hex.pm/packages/ex_sdp)
[![API Docs](https://img.shields.io/badge/api-docs-yellow.svg?style=flat)](https://hexdocs.pm/ex_sdp/)
[![CircleCI](https://circleci.com/gh/membraneframework/ex_sdp.svg?style=svg)](https://circleci.com/gh/membraneframework/ex_sdp)

Parser and serializer for Session Description Protocol. Based on [RFC4566](https://tools.ietf.org/html/rfc4566)

## Installation

The package can be installed by adding `ex_sdp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ex_sdp, "~> 0.1.0"}
  ]
end
```

## Usage

### Parser

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
|> ExSDP.parse()

# =>
{:ok,
 %ExSDP{
   attributes: [
     %ExSDP.Attribute{key: "key", value: "value"},
     %ExSDP.Attribute{key: nil, value: :recvonly}
   ],
   bandwidth: [%ExSDP.Bandwidth{bandwidth: 256, type: :AS}],
   connection_data: %ExSDP.ConnectionData{
     addresses: [
       %ExSDP.ConnectionData.IP4{
         ttl: 127,
         value: {224, 2, 17, 12}
       }
     ],
     network_type: "IN"
   },
   email: %ExSDP.Email{value: "j.doe@example.com (Jane Doe)"},
   encryption: %ExSDP.Encryption{key: "key", method: :clear},
   media: [
     %ExSDP.Media{
       attributes: [],
       bandwidth: [%ExSDP.Bandwidth{bandwidth: 256, type: :AS}],
       connection_data: %ExSDP.ConnectionData{
         addresses: [
           %ExSDP.ConnectionData.IP4{
             ttl: 127,
             value: {224, 2, 17, 12}
           }
         ],
         network_type: "IN"
       },
       encryption: %ExSDP.Encryption{key: nil, method: :prompt},
       fmt: [0],
       ports: [49170],
       protocol: "RTP/AVP",
       title: "Sample media title",
       type: :audio
     },
     %ExSDP.Media{
       attributes: [
         %ExSDP.Attribute{
           key: :rtpmap,
           value: %ExSDP.Attribute.RTPMapping{
             clock_rate: 90000,
             encoding: "h263-1998",
             params: nil,
             payload_type: 99
           }
         }
       ],
       bandwidth: [%ExSDP.Bandwidth{bandwidth: 256, type: :AS}],
       connection_data: %ExSDP.ConnectionData{
         addresses: [
           %ExSDP.ConnectionData.IP4{
             ttl: 127,
             value: {224, 2, 17, 12}
           }
         ],
         network_type: "IN"
       },
       encryption: %ExSDP.Encryption{key: "key", method: :clear},
       fmt: 'c',
       ports: [51372],
       protocol: "RTP/AVP",
       title: nil,
       type: :video
     }
   ],
   origin: %ExSDP.Origin{
     address: %ExSDP.ConnectionData.IP4{
       ttl: nil,
       value: {10, 47, 16, 5}
     },
     session_id: "2890844526",
     session_version: "2890842807",
     username: "jdoe"
   },
   phone_number: %ExSDP.PhoneNumber{value: "111 111 111"},
   session_information: %ExSDP.SessionInformation{
     value: "A Seminar on the session description protocol"
   },
   session_name: %ExSDP.SessionName{
     value: "Very fancy session name"
   },
   time_repeats: [
     %ExSDP.RepeatTimes{
       active_duration: 3600,
       offsets: [0, 90000],
       repeat_interval: 604800
     },
     %ExSDP.RepeatTimes{
       active_duration: 3600,
       offsets: [0, 90000],
       repeat_interval: 604800
     }
   ],
   time_zones_adjustments: %ExSDP.Timezone{
     corrections: [
       %ExSDP.Timezone.Correction{
         adjustment_time: 2882844526,
         offset: -1
       },
       %ExSDP.Timezone.Correction{
         adjustment_time: 2898848070,
         offset: 0
       }
     ]
   },
   timing: %ExSDP.Timing{
     start_time: 2873397496,
     stop_time: 2873404696
   },
   uri: %ExSDP.URI{
     value: "http://www.example.com/seminars/sdp.pdf"
   },
   version: %ExSDP.Version{value: 0}
 }}
```

### Serializer

Serializer serializes `ExSDP` struct to a string with `\r\n` terminated lines.

```elixir
%ExSDP{
   attributes: [
     %ExSDP.Attribute{key: "key", value: "value"},
     %ExSDP.Attribute{key: nil, value: :recvonly}
   ],
   bandwidth: [%ExSDP.Bandwidth{bandwidth: 256, type: :AS}],
   connection_data: %ExSDP.ConnectionData{
     addresses: [
       %ExSDP.ConnectionData.IP4{
         ttl: 127,
         value: {224, 2, 17, 12}
       }
     ],
     network_type: "IN"
   },
   email: %ExSDP.Email{value: "j.doe@example.com (Jane Doe)"},
   encryption: %ExSDP.Encryption{key: "key", method: :clear},
   media: [
     %ExSDP.Media{
       attributes: [],
       bandwidth: [%ExSDP.Bandwidth{bandwidth: 256, type: :AS}],
       connection_data: %ExSDP.ConnectionData{
         addresses: [
           %ExSDP.ConnectionData.IP4{
             ttl: 127,
             value: {224, 2, 17, 12}
           }
         ],
         network_type: "IN"
       },
       encryption: %ExSDP.Encryption{key: nil, method: :prompt},
       fmt: [0],
       ports: [49170],
       protocol: "RTP/AVP",
       title: "Sample media title",
       type: :audio
     },
     %ExSDP.Media{
       attributes: [
         %ExSDP.Attribute{
           key: :rtpmap,
           value: %ExSDP.Attribute.RTPMapping{
             clock_rate: 90000,
             encoding: "h263-1998",
             params: nil,
             payload_type: 99
           }
         }
       ],
       bandwidth: [%ExSDP.Bandwidth{bandwidth: 256, type: :AS}],
       connection_data: %ExSDP.ConnectionData{
         addresses: [
           %ExSDP.ConnectionData.IP4{
             ttl: 127,
             value: {224, 2, 17, 12}
           }
         ],
         network_type: "IN"
       },
       encryption: %ExSDP.Encryption{key: "key", method: :clear},
       fmt: 'c',
       ports: [51372],
       protocol: "RTP/AVP",
       title: nil,
       type: :video
     }
   ],
   origin: %ExSDP.Origin{
     address: %ExSDP.ConnectionData.IP4{
       ttl: nil,
       value: {10, 47, 16, 5}
     },
     session_id: "2890844526",
     session_version: "2890842807",
     username: "jdoe"
   },
   phone_number: %ExSDP.PhoneNumber{value: "111 111 111"},
   session_information: %ExSDP.SessionInformation{
     value: "A Seminar on the session description protocol"
   },
   session_name: %ExSDP.SessionName{
     value: "Very fancy session name"
   },
   time_repeats: [
     %ExSDP.RepeatTimes{
       active_duration: 3600,
       offsets: [0, 90000],
       repeat_interval: 604800
     },
     %ExSDP.RepeatTimes{
       active_duration: 3600,
       offsets: [0, 90000],
       repeat_interval: 604800
     }
   ],
   time_zones_adjustments: %ExSDP.Timezone{
     corrections: [
       %ExSDP.Timezone.Correction{
         adjustment_time: 2882844526,
         offset: -1
       },
       %ExSDP.Timezone.Correction{
         adjustment_time: 2898848070,
         offset: 0
       }
     ]
   },
   timing: %ExSDP.Timing{
     start_time: 2873397496,
     stop_time: 2873404696
   },
   uri: %ExSDP.URI{
     value: "http://www.example.com/seminars/sdp.pdf"
   },
   version: %ExSDP.Version{value: 0}
}
|> ExSDP.serialize
|> String.replace("\r\n", "\n")

# =>
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
r=604800 3600 0 90000
z=2882844526 -1h 2898848070 0
k=clear:key
a=key:value
a=recvonly
m=audio 49170 RTP/AVP 0
i=Sample media title
c=IN IP4 224.2.17.12/127
b=AS:256
k=prompt
m=video 51372 RTP/AVP 99
c=IN IP4 224.2.17.12/127
b=AS:256
k=clear:key
a=rtpmap:99 h263-1998/90000
"""
```

## Copyright and License

Copyright 2020, [Software Mansion](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

[![Software Mansion](https://logo.swmansion.com/logo?color=white&variant=desktop&width=200&tag=membrane-github)](https://swmansion.com/?utm_source=git&utm_medium=readme&utm_campaign=membrane)

Licensed under the [Apache License, Version 2.0](LICENSE)

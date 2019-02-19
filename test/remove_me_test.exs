defmodule A do
  use ExUnit.Case

  test "" do
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
    |> String.replace("\n", "\r\n")
    |> Membrane.Protocol.SDP.parse()
    |> IO.inspect()
  end

  test "b" do
    """
    v=0
    o=- 1045516125 1045516125 IN IP4 184.72.239.149
    s=BigBuckBunny_115k.mov
    c=IN IP4 184.72.239.149
    t=0 0
    a=sdplang:en
    a=range:npt=0- 596.48
    a=control:*
    m=audio 0 RTP/AVP 96
    a=rtpmap:96 mpeg4-generic/12000/2
    a=fmtp:96 profile-level-id=1;mode=AAC-hbr;sizelength=13;indexlength=3;indexdeltalength=3;config=1490
    a=control:trackID=1\r\nm=video 0 RTP/AVP 97
    a=rtpmap:97 H264/90000
    a=fmtp:97 packetization-mode=1;profile-level-id=42C01E;sprop-parameter-sets=Z0LAHtkDxWhAAAADAEAAAAwDxYuS,aMuMsg==
    a=cliprect:0,0,160,240
    a=framesize:97 240-160
    a=framerate:24.0
    a=control:trackID=2
    """
    |> String.replace("\n", "\r\n")
    |> Membrane.Protocol.SDP.parse()
    |> IO.inspect()
  end
end

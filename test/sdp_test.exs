defmodule Membrane.Protocol.SDPTest do
  use ExUnit.Case
  import ExUnit.CaptureLog

  alias Membrane.Support.SpecHelper
  alias Membrane.Protocol.SDP

  @error_color_prefix "\e[31m"
  @back_to_normal "\e[0m"

  test "SDP parser parses artificially long and complex session description" do
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
             |> IO.inspect()
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
                   |> SpecHelper.from_binary()
                   |> SDP.parse()
        end)

      assert logs =~ """
             Error whil parsing media:
             m=video 51372 RTP/AVP 99

             Attributes:
             a=rtpmap:99 h263-1998/90000
             c=invalid data

             with reason: invalid_connection_information
             """

      assert error_log?(logs)
    end

    test "when parsing non-media" do
      logs =
        capture_log(fn ->
          assert {:error, _} =
                   "o=jdoe 2890844526 2890842807 IN"
                   |> SpecHelper.from_binary()
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

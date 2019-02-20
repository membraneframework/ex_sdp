defmodule Membrane.Protocol.SDP.MediaTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Media

  describe "Media parser" do
    test "processes valid media description" do
      assert {:ok, media} =
               "video 49170 RTP/AVP 31"
               |> Media.parse()
               |> IO.inspect()
    end

    test "processes valid media description with multiple ports" do
      assert {:ok, media} =
               "video 49170/2 RTP/AVP 31"
               |> Media.parse()
               |> IO.inspect()
    end
  end
end

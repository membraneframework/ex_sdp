defmodule ExSDP.SerializerTest do
  use ExUnit.Case

  alias ExSDP.Attribute.RTPMapping
  alias ExSDP.Serializer

  describe "Attribute serialization" do
    test "serializes framerate attribute" do
      assert Serializer.maybe_serialize("a", {:framerate, 30}) == "a=framerate:30"
    end

    test "serializes framerate attribute with \"/\"" do
      assert Serializer.maybe_serialize("a", {:framerate, {30, 1}}) == "a=framerate:30/1"
    end

    test "serializes flag attributes" do
      assert Serializer.maybe_serialize("a", :sendrecv) == "a=sendrecv"
    end

    test "serializes numeric attributes" do
      assert Serializer.maybe_serialize("a", {:maxptime, "100"}) == "a=maxptime:100"
    end

    test "serializes value attributes" do
      assert Serializer.maybe_serialize("a", {:type, "some-type"}) == "a=type:some-type"
    end

    test "serializes rtpmap attributes" do
      mapping = %RTPMapping{
        payload_type: 101,
        encoding: "h263-1998",
        clock_rate: 90_000
      }

      assert Serializer.maybe_serialize("a", mapping) == "a=rtpmap:101 h263-1998/90000"
    end

    test "serializes list of attributes" do
      attributes = [:sendrecv, {:maxptime, "100"}, {:type, "some-type"}]

      assert Serializer.maybe_serialize("a", attributes) ==
               "a=sendrecv\na=maxptime:100\na=type:some-type"
    end
  end
end

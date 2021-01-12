defmodule ExSDP.AttributeTest do
  use ExUnit.Case

  alias ExSDP.{Attribute, Serializer, Fixtures}
  @eol Fixtures.default_eol()

  describe "Attribute parser" do
    test "handles framerate" do
      assert {:ok, %Attribute{key: :framerate, value: {30, 1}}} =
               Attribute.parse("framerate:30/1")
    end

    test "handles directly assignable attributes" do
      assert {:ok, %Attribute{key: :cat, value: "category"}} = Attribute.parse("cat:category")
    end

    test "handles known integer attributes" do
      assert {:ok, %Attribute{key: :quality, value: 7}} = Attribute.parse("quality:7")
    end

    test "returns an error if attribute supposed to be numeric but isn't" do
      assert {:error, :invalid_attribute} = Attribute.parse("ptime:g7")
    end

    test "handles known flags" do
      assert {:ok, %Attribute{value: :recvonly}} = Attribute.parse("recvonly")
    end

    test "handles unknown attribute" do
      assert {:ok, %Attribute{value: "otherattr"}} = Attribute.parse("otherattr")
    end
  end

  describe "Media attribute parser" do
    test "handles rtpmaping" do
      assert {:ok, %Attribute{key: :rtpmap, value: %Attribute.RTPMapping{}}} =
               Attribute.parse_media_attribute(
                 %Attribute{key: :rtpmap, value: "98 L16/16000/2"},
                 :audio
               )
    end

    test "handles unknown attribute" do
      assert {:ok, %Attribute{key: "dunno", value: "123"}} =
               Attribute.parse_media_attribute(%Attribute{key: "dunno", value: "123"}, :message)
    end
  end

  describe "Attribute serializer" do
    test "serializes framerate attribute" do
      assert Serializer.serialize(%Attribute{key: :framerate, value: "value"}) ==
               "a=framerate:value#{@eol}"
    end

    test "serializes flag attributes" do
      assert Serializer.serialize(%Attribute{value: :sendrecv}) == "a=sendrecv#{@eol}"
    end

    test "serializes numeric attributes" do
      assert Serializer.serialize(%Attribute{key: :maxptime, value: "100"}) ==
               "a=maxptime:100#{@eol}"
    end

    test "serializes value attributes" do
      assert Serializer.serialize(%Attribute{key: :type, value: "some-type"}) ==
               "a=type:some-type#{@eol}"
    end

    test "serializes custom attributes" do
      assert Serializer.serialize(%Attribute{key: "custom", value: "attribute"}) ==
               "a=custom:attribute#{@eol}"
    end
  end
end

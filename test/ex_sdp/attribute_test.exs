defmodule ExSDP.AttributeTest do
  use ExUnit.Case

  alias ExSDP.Attribute

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
      attribute = %Attribute{key: :framerate, value: "value"}
      assert "#{attribute}" == "framerate:value"
    end

    test "serializes flag attributes" do
      attribute = %Attribute{value: :sendrecv}
      assert "#{attribute}" == "sendrecv"
    end

    test "serializes numeric attributes" do
      attribute = %Attribute{key: :maxptime, value: "100"}
      assert "#{attribute}" == "maxptime:100"
    end

    test "serializes value attributes" do
      attribute = %Attribute{key: :type, value: "some-type"}
      assert "#{attribute}" == "type:some-type"
    end

    test "serializes custom attributes" do
      attribute = %Attribute{key: "custom", value: "attribute"}
      assert "#{attribute}" == "custom:attribute"
    end
  end
end

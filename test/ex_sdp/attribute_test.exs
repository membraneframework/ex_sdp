defmodule ExSDP.AttributeTest do
  use ExUnit.Case

  alias ExSDP.Attribute

  describe "Attribute parser" do
    test "handles framerate" do
      assert {:ok, {:framerate, {30, 1}}} = Attribute.parse("framerate:30/1")
      assert {:ok, {:framerate, 30.0}} = Attribute.parse("framerate:30")
      assert {:ok, {:framerate, 30.0}} = Attribute.parse("framerate:30.0")
      assert {:error, :invalid_framerate} = Attribute.parse("framerate:foobar")
      assert {:error, :invalid_framerate} = Attribute.parse("framerate:30abc")
    end

    test "handles directly assignable attributes" do
      assert {:ok, {:cat, "category"}} = Attribute.parse("cat:category")
    end

    test "handles known integer attributes" do
      assert {:ok, {:quality, 7}} = Attribute.parse("quality:7")
    end

    test "returns an error if attribute supposed to be numeric but isn't" do
      assert {:error, :invalid_attribute} = Attribute.parse("ptime:g7")
    end

    test "handles known flags" do
      assert {:ok, :recvonly} = Attribute.parse("recvonly")
    end

    test "handles unknown attribute" do
      assert {:ok, "otherattr"} = Attribute.parse("otherattr")
    end

    test "handles fingerprint with a hash-func token in any case" do
      value = "3B:1E:81:0E:64:41:BC:F5:A2:96:8C:A6:1F:11:26:2C:D5:B7:52:5C"

      assert {:ok, {:fingerprint, {:sha1, ^value}}} =
               Attribute.parse("fingerprint:sha-1 " <> value)

      assert {:ok, {:fingerprint, {:sha1, ^value}}} =
               Attribute.parse("fingerprint:SHA-1 " <> value)

      assert {:ok, {:fingerprint, {:sha256, ^value}}} =
               Attribute.parse("fingerprint:SHA-256 " <> value)

      assert {:ok, {:fingerprint, {:sha256, ^value}}} =
               Attribute.parse("fingerprint:Sha-256 " <> value)
    end

    test "rejects a fingerprint with an unknown hash function" do
      assert {:error, :invalid_fingerprint} = Attribute.parse("fingerprint:md5 AB:CD")
    end
  end
end

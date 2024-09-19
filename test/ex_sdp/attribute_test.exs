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
  end
end

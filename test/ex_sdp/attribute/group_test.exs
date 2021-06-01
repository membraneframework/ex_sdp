defmodule ExSDP.Attribute.GroupTest do
  use ExUnit.Case

  alias ExSDP.Attribute.Group

  describe "Group parser" do
    @tag :debug
    test "parses group" do
      group = "BUNDLE 1 2 3 4"
      expected = %Group{semantics: "BUNDLE", mids: ["1", "2", "3", "4"]}
      assert {:ok, expected} == Group.parse(group)
    end

    test "parses group without mids" do
      group = "BUNDLE"
      expected = %Group{semantics: "BUNDLE", mids: []}
      assert {:ok, expected} == Group.parse(group)
    end

    test "returns an error when group is invalid" do
      group = "BUNDLE "
      assert {:error, :invalid_group} == Group.parse(group)
    end
  end

  describe "Group serializer" do
    test "serializes Group" do
      group = %Group{semantics: "BUNDLE", mids: ["1", "2", "3", "4"]}
      assert "#{group}" == "group:BUNDLE 1 2 3 4"
    end

    test "serializes Group without mids" do
      group = %Group{semantics: "BUNDLE", mids: []}
      assert "#{group}" == "group:BUNDLE"
    end
  end
end

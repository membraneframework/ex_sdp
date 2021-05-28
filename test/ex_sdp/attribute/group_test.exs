defmodule ExSDP.Attribute.GroupTest do
  use ExUnit.Case

  alias ExSDP.Attribute.Group

  describe "Group parser" do
    test "parses group" do
      group = "BUNDLE 1 2 3 4"
      expected = %Group{semantics: "BUNDLE", mids: ["1", "2", "3", "4"]}
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

    test "doesn't produce string when there are no mids" do
      group = %Group{semantics: "BUNDLE", mids: []}
      assert "#{group}" == ""
    end
  end
end

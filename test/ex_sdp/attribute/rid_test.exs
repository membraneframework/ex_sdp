defmodule ExSDP.Attribute.RIDTest do
  use ExUnit.Case, async: true

  alias ExSDP.Attribute.RID

  test "parse/1" do
    assert {:ok, rid} = RID.parse("l recv")
    assert %RID{id: "l", direction: :recv, pt: nil, restrictions: []} == rid

    assert {:ok, rid} = RID.parse("h send pt=4,5")
    assert %RID{id: "h", direction: :send, pt: [4, 5], restrictions: []} == rid

    assert {:ok, rid} = RID.parse("m send max-width=1280;max-fps=30")

    assert %RID{
             id: "m",
             direction: :send,
             pt: nil,
             restrictions: [{"max-width", "1280"}, {"max-fps", "30"}]
           } == rid

    assert {:ok, rid} = RID.parse("m recv pt=111;max-fps=30")
    assert %RID{id: "m", direction: :recv, pt: [111], restrictions: [{"max-fps", "30"}]} == rid
  end

  test "to_string/1" do
    rid = %RID{id: "l", direction: :recv, pt: nil, restrictions: []}
    assert to_string(rid) == "rid:l recv"

    rid = %RID{id: "h", direction: :send, pt: [4, 5], restrictions: []}
    assert to_string(rid) == "rid:h send pt=4,5"

    rid = %RID{
      id: "m",
      direction: :send,
      pt: nil,
      restrictions: [{"max-width", "1280"}, {"max-fps", "30"}]
    }

    assert to_string(rid) == "rid:m send max-width=1280;max-fps=30"

    rid = %RID{id: "m", direction: :recv, pt: [111], restrictions: [{"max-fps", "30"}]}
    assert to_string(rid) == "rid:m recv pt=111;max-fps=30"
  end
end

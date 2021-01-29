defmodule ExSDP.Attribute.SsrcTest do
  use ExUnit.Case

  alias ExSDP.Attribute.Ssrc

  describe "Ssrc parser" do
    test "parses ssrc with attribute and value" do
      ssrc = "4112531724 cname:HPd3XfRHXYUxzfsJ"
      expected = %Ssrc{id: 4_112_531_724, attribute: "cname", value: "HPd3XfRHXYUxzfsJ"}
      assert {:ok, expected} == Ssrc.parse(ssrc)
    end

    test "parses ssrc only with attribute" do
      ssrc = "4112531724 some-attr"
      expected = %Ssrc{id: 4_112_531_724, attribute: "some-attr", value: nil}
      assert {:ok, expected} == Ssrc.parse(ssrc)
    end

    test "returns an error when there is no attribute after id" do
      ssrc = "4112531724"
      assert {:error, :invalid_ssrc} = Ssrc.parse(ssrc)
    end
  end

  describe "Ssrc serializer" do
    test "serializes ssrc with attribute and value" do
      ssrc = %Ssrc{id: 4_112_531_724, attribute: "cname", value: "HPd3XfRHXYUxzfsJ"}
      assert "#{ssrc}" == "ssrc:4112531724 cname:HPd3XfRHXYUxzfsJ"
    end

    test "serializes ssrc only with attribute" do
      ssrc = %Ssrc{id: 4_112_531_724, attribute: "some-attr"}
      assert "#{ssrc}" == "ssrc:4112531724 some-attr"
    end
  end
end

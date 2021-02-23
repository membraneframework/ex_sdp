defmodule ExSDP.Attribute.SSRCTest do
  use ExUnit.Case

  alias ExSDP.Attribute.SSRC

  describe "SSRC parser" do
    test "parses ssrc with attribute and value" do
      ssrc = "4112531724 cname:HPd3XfRHXYUxzfsJ"
      expected = %SSRC{id: 4_112_531_724, attribute: "cname", value: "HPd3XfRHXYUxzfsJ"}
      assert {:ok, expected} == SSRC.parse(ssrc)
    end

    test "parses ssrc only with attribute" do
      ssrc = "4112531724 some-attr"
      expected = %SSRC{id: 4_112_531_724, attribute: "some-attr", value: nil}
      assert {:ok, expected} == SSRC.parse(ssrc)
    end

    test "returns an error when there is no attribute after id" do
      ssrc = "4112531724"
      assert {:error, :invalid_ssrc} = SSRC.parse(ssrc)
    end
  end

  describe "SSRC serializer" do
    test "serializes SSRC with attribute and value" do
      ssrc = %SSRC{id: 4_112_531_724, attribute: "cname", value: "HPd3XfRHXYUxzfsJ"}
      assert "#{ssrc}" == "ssrc:4112531724 cname:HPd3XfRHXYUxzfsJ"
    end

    test "serializes SSRC only with attribute" do
      ssrc = %SSRC{id: 4_112_531_724, attribute: "some-attr"}
      assert "#{ssrc}" == "ssrc:4112531724 some-attr"
    end
  end
end

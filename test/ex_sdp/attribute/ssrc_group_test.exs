defmodule ExSDP.Attribute.SSRCGroupTest do
  use ExUnit.Case, async: true

  alias ExSDP.Attribute.SSRCGroup

  describe "Flow identification - RTX SSRC" do
    setup do
      %{
        attr_string: "FID 2231627014 632943048",
        struct: %SSRCGroup{semantics: "FID", ssrcs: [2_231_627_014, 632_943_048]}
      }
    end

    test "parsing", ctx do
      assert SSRCGroup.parse(ctx.attr_string) == {:ok, ctx.struct}
    end

    test "serialization", ctx do
      assert to_string(ctx.struct) == "ssrc-group:" <> ctx.attr_string
    end
  end

  test "Error when parsing invalid entry" do
    assert SSRCGroup.parse("125411114") == {:error, :invalid_ssrc_group}
    assert SSRCGroup.parse("FID") == {:error, :invalid_ssrc_group}

    assert SSRCGroup.parse("FID 555abcs1234") == {:error, :invalid_ssrc}
    assert SSRCGroup.parse("FID 555abcs1234 4125411114") == {:error, :invalid_ssrc}
    assert SSRCGroup.parse("FID 55521331234 a125411114") == {:error, :invalid_ssrc}
  end
end

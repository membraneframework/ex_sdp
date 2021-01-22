defmodule ExSDP.Attribute.FmtpTest do
  use ExUnit.Case

  alias ExSDP.Attribute.Fmtp

  describe "Fmtp parser" do
    test "parses fmtp" do
      fmtp = "108 profile-level-id=42e01f;level-asymmetry-allowed=1;packetization-mode=1"

      expected = %Fmtp{
        pt: 108,
        profile_level_id: 0x42E01F,
        level_asymmetry_allowed: true,
        packetization_mode: 1
      }

      assert {:ok, expected} == Fmtp.parse(fmtp)
    end

    test "returns an error when there is unsupported parameter" do
      fmtp = "108 profile-level-id=42e01f;level-asymmetry-allowed=1;unsupported-param=1"
      assert {:error, {:invalid_fmtp, :unsupported_parameter}} = Fmtp.parse(fmtp)
    end
  end

  describe "Fmtp serializer" do
    test "serializes fmtp with numeric and boolean values" do
      fmtp = %Fmtp{
        pt: 120,
        minptime: 10,
        useinbandfec: true
      }

      assert "#{fmtp}" == "fmtp:120 minptime=10;useinbandfec=1"
    end

    test "serializes fmtp with hexadecimal numeric values and boolean values" do
      expected = "fmtp:108 profile-level-id=42e01f;level-asymmetry-allowed=1;packetization-mode=1"

      fmtp = %Fmtp{
        pt: 108,
        profile_level_id: 0x42E01F,
        level_asymmetry_allowed: true,
        packetization_mode: 1
      }

      assert "#{fmtp}" == expected
    end
  end
end

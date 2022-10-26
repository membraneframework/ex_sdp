defmodule ExSDP.Attribute.FMTPTest do
  use ExUnit.Case

  alias ExSDP.Attribute.FMTP

  describe "FMTP parser" do
    test "parses proper fmtp" do
      fmtp = "108 profile-level-id=42e01f;level-asymmetry-allowed=1;packetization-mode=1"

      expected = %FMTP{
        pt: 108,
        profile_level_id: 0x42E01F,
        level_asymmetry_allowed: true,
        packetization_mode: 1
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "parses proper fmtp with RED parameter" do
      fmtp = "63 111/111"

      expected = %FMTP{
        pt: 63,
        redundant_payloads: [111, 111]
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "returns an error when RED parameter is invalid" do
      fmtp = "63 111/111/130"
      assert {:error, :red_not_in_0_128_range} == FMTP.parse(fmtp)
    end

    test "parses proper fmtp with simple DTMF tones parameter" do
      fmtp = "100 0-15"

      expected = %FMTP{
        pt: 100,
        dtmf_tones: "0-15"
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "parses proper fmtp with complex DTMF tones parameter" do
      fmtp = "100 0-15,66,70"

      expected = %FMTP{
        pt: 100,
        dtmf_tones: "0-15,66,70"
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "returns an error when DTMF tone is too big" do
      fmtp = "100 0-15,256"
      assert {:error, :invalid_dtmf_tones} = FMTP.parse(fmtp)
    end

    test "returns an error when DTMF tone range is invalid" do
      fmtp = "100 4-2"
      assert {:error, :invalid_dtmf_tones} = FMTP.parse(fmtp)
    end

    test "returns an error when DTMF tone range is too big" do
      fmtp = "100 0-256"
      assert {:error, :invalid_dtmf_tones} = FMTP.parse(fmtp)
    end

    test "returns an error when there is unsupported parameter" do
      fmtp = "108 profile-level-id=42e01f;level-asymmetry-allowed=1;unsupported-param=1"
      assert {:ok, %{unknown: ["unsupported-param=1"]}} = FMTP.parse(fmtp)
    end
  end

  describe "FMTP serializer" do
    test "serializes FMTP with numeric and boolean values" do
      fmtp = %FMTP{
        pt: 120,
        minptime: 10,
        useinbandfec: true
      }

      assert "#{fmtp}" == "fmtp:120 minptime=10;useinbandfec=1"
    end

    test "serializes FMTP with hexadecimal numeric values and boolean values" do
      expected = "fmtp:108 profile-level-id=42e01f;level-asymmetry-allowed=1;packetization-mode=1"

      fmtp = %FMTP{
        pt: 108,
        profile_level_id: 0x42E01F,
        level_asymmetry_allowed: true,
        packetization_mode: 1
      }

      assert "#{fmtp}" == expected
    end

    test "serializes FMTP with list values" do
      expected = "fmtp:63 111/111"

      fmtp = %FMTP{
        pt: 63,
        redundant_payloads: [111, 111]
      }

      assert "#{fmtp}" == expected
    end
  end
end

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
        redundant_payloads: [111]
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "returns an error when RED parameter is invalid" do
      fmtp = "63 111/111/130"
      assert {:error, :invalid_pt} == FMTP.parse(fmtp)
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

    test "parses fmtp with spaces after semi-colons" do
      fmtp = "117 maxplaybackrate=16000; maxaveragebitrate=24000; cbr=0; useinbandfec=0; usedtx=0"

      expected = %FMTP{
        pt: 117,
        maxplaybackrate: 16_000,
        maxaveragebitrate: 24_000,
        cbr: false,
        usedtx: false,
        useinbandfec: false
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "parses fmtp with ptime, maxptime, and sprop-maxcapturerate parameters" do
      fmtp = "121 ptime=20;maxptime=60;cbr=0;sprop-maxcapturerate=16000"

      expected = %FMTP{
        pt: 121,
        ptime: 20,
        maxptime: 60,
        cbr: false,
        sprop_maxcapturerate: 16_000
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "parses fmtp with sprop-parameter-sets parameters" do
      fmtp =
        "105 profile-level-id=64001f; packetization-mode=1; " <>
          "sprop-parameter-sets=Z2QAH62EAQwgCGEAQwgCGEAQwgCEO1AoAt03AQEBQAAA+gAAOpgh,aO4xshs="

      expected = %FMTP{
        pt: 105,
        profile_level_id: 0x64001F,
        packetization_mode: 1,
        sprop_parameter_sets: %{
          sps:
            <<103, 100, 0, 31, 173, 132, 1, 12, 32, 8, 97, 0, 67, 8, 2, 24, 64, 16, 194, 0, 132,
              59, 80, 40, 2, 221, 55, 1, 1, 1, 64, 0, 0, 250, 0, 0, 58, 152, 33>>,
          pps: <<104, 238, 49, 178, 27>>
        }
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "parses fmtp with sprop-*ps" do
      fmtp =
        "96 profile-space=0;profile-id=1;tier-flag=0;level-id=150;interop-constraints=B00000000000;" <>
          "sprop-vps=QAEMAf//AWAAAAMAAAMAAAMAAAMAlqwJAAAAAQ==;" <>
          "sprop-sps=QgEBAWAAAAMAAAMAAAMAAAMAlqAB4CACHH+KrTuiS7IAAAAB,QgEBAWAAAAMAsAAAAwAAAwCZoAHgIAIcWNrkkUvzcBAQEAg=;" <>
          "sprop-pps=RAHAcvCcFAobJA==,RAHA8vA7NA=="

      expected = %FMTP{
        pt: 96,
        profile_space: 0,
        profile_id: 1,
        tier_flag: false,
        level_id: 150,
        interop_constraints: 0xB00000000000,
        sprop_vps: [
          <<64, 1, 12, 1, 255, 255, 1, 96, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 150, 172, 9, 0,
            0, 0, 1>>
        ],
        sprop_sps: [
          <<66, 1, 1, 1, 96, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 150, 160, 1, 224, 32, 2, 28,
            127, 138, 173, 59, 162, 75, 178, 0, 0, 0, 1>>,
          <<66, 1, 1, 1, 96, 0, 0, 3, 0, 176, 0, 0, 3, 0, 0, 3, 0, 153, 160, 1, 224, 32, 2, 28,
            88, 218, 228, 145, 75, 243, 112, 16, 16, 16, 8>>
        ],
        sprop_pps: [
          <<68, 1, 192, 114, 240, 156, 20, 10, 27, 36>>,
          <<68, 1, 192, 242, 240, 59, 52>>
        ]
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

    test "saves unsupported parameter as unknown" do
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

    test "serializes FMTP with sprop-parameter-sets" do
      expected =
        "fmtp:96 profile-level-id=420029;packetization-mode=1;sprop-parameter-sets=Z0IAKeKQFAe2AtwEBAaQeJEV,aM48gA=="

      fmtp = %FMTP{
        pt: 96,
        packetization_mode: 1,
        profile_level_id: 0x420029,
        sprop_parameter_sets: %{
          sps: <<103, 66, 0, 41, 226, 144, 20, 7, 182, 2, 220, 4, 4, 6, 144, 120, 145, 21>>,
          pps: <<104, 206, 60, 128>>
        }
      }

      assert "#{fmtp}" == expected
    end

    test "serializes FMTP with sprop-*ps" do
      expected =
        "fmtp:96 profile-space=0;tier-flag=0;level-id=150;interop-constraints=b00000000000;" <>
          "sprop-vps=QAEMAf//AWAAAAMAAAMAAAMAAAMAlqwJAAAAAQ==;" <>
          "sprop-sps=QgEBAWAAAAMAAAMAAAMAAAMAlqAB4CACHH+KrTuiS7IAAAAB,QgEBAWAAAAMAsAAAAwAAAwCZoAHgIAIcWNrkkUvzcBAQEAg=;" <>
          "sprop-pps=RAHAcvCcFAobJA==,RAHA8vA7NA==;profile-id=1"

      fmtp = %FMTP{
        pt: 96,
        profile_space: 0,
        profile_id: 1,
        tier_flag: false,
        level_id: 150,
        interop_constraints: 0xB00000000000,
        sprop_vps: [
          <<64, 1, 12, 1, 255, 255, 1, 96, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 150, 172, 9, 0,
            0, 0, 1>>
        ],
        sprop_sps: [
          <<66, 1, 1, 1, 96, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 0, 3, 0, 150, 160, 1, 224, 32, 2, 28,
            127, 138, 173, 59, 162, 75, 178, 0, 0, 0, 1>>,
          <<66, 1, 1, 1, 96, 0, 0, 3, 0, 176, 0, 0, 3, 0, 0, 3, 0, 153, 160, 1, 224, 32, 2, 28,
            88, 218, 228, 145, 75, 243, 112, 16, 16, 16, 8>>
        ],
        sprop_pps: [
          <<68, 1, 192, 114, 240, 156, 20, 10, 27, 36>>,
          <<68, 1, 192, 242, 240, 59, 52>>
        ]
      }

      assert "#{fmtp}" == expected
    end
  end
end

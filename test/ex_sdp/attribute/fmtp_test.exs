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

    test "parses proper fmtp with G7221 bitrate parameter" do
      fmtp = "98 bitrate=48000"

      expected = %FMTP{
        pt: 98,
        bitrate: 48_000
      }

      assert {:ok, expected} == FMTP.parse(fmtp)
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

    test "parses fmtp with an empty sprop-parameter-sets as if it were absent" do
      # Some cameras (e.g. Hikvision door stations) send the key with no value
      # and carry SPS/PPS in-band.
      fmtp = "96 profile-level-id=420029; packetization-mode=1; sprop-parameter-sets="

      expected = %FMTP{pt: 96, profile_level_id: 0x420029, packetization_mode: 1}

      assert {:ok, expected} == FMTP.parse(fmtp)
    end

    test "parses fmtp with more than two sets in sprop-parameter-sets" do
      sps = <<103, 66, 0, 31>>
      pps = <<104, 206, 60, 128>>
      sets = &Enum.map_join(&1, ",", fn set -> Base.encode64(set) end)

      import ExUnit.CaptureLog

      for list <- [[sps, pps, <<104, 238, 49, 178>>], [sps, <<103, 100, 0, 31>>, pps]] do
        {result, log} = with_log(fn -> FMTP.parse("96 sprop-parameter-sets=#{sets.(list)}") end)

        assert {:ok, %FMTP{sprop_parameter_sets: %{sps: ^sps, pps: ^pps}}} = result
        assert log =~ "sprop-parameter-sets"
      end

      assert {:ok, %FMTP{sprop_parameter_sets: %{sps: ^sps, pps: ^pps}}} =
               FMTP.parse("96 sprop-parameter-sets=#{sets.([sps, pps])},")

      assert {:error, :invalid_sprop_parameter_sets} =
               FMTP.parse("96 sprop-parameter-sets=#{sets.([sps, pps])},!!!")

      assert {:error, :invalid_sprop_parameter_sets} =
               FMTP.parse("96 sprop-parameter-sets=#{sets.([sps, sps, sps])}")
    end

    test "parses fmtp with sprop-parameter-sets that lack base64 padding" do
      assert {:ok,
              %FMTP{sprop_parameter_sets: %{sps: <<103, 66, 0, 31>>, pps: <<104, 206, 60, 128>>}}} =
               FMTP.parse("96 sprop-parameter-sets=Z0IAHw,aM48gA")

      assert {:ok, %FMTP{sprop_sps: [<<66, 1, 1>>], sprop_pps: [<<68, 1, 192>>]}} =
               FMTP.parse("96 sprop-sps=QgEB;sprop-pps=RAHA")
    end

    test "parses fmtp with sprop-parameter-sets that carry only an SPS" do
      assert {:ok, %FMTP{sprop_parameter_sets: %{sps: <<103, 66, 0, 31>>, pps: nil}} = fmtp} =
               FMTP.parse("96 sprop-parameter-sets=Z0IAHw==")

      assert to_string(fmtp) == "fmtp:96 sprop-parameter-sets=Z0IAHw=="

      assert {:error, :invalid_sprop_parameter_sets} =
               FMTP.parse("96 sprop-parameter-sets=aM48gA==")
    end

    test "still refuses a sprop-parameter-sets that is not valid base64" do
      assert {:error, :invalid_sprop_parameter_sets} ==
               FMTP.parse("96 packetization-mode=1; sprop-parameter-sets=not-base64,*")
    end

    test "parses H265 tx-mode" do
      for tx_mode <- [:SRST, :MRST, :MRMT] do
        assert {:ok, %FMTP{tx_mode: ^tx_mode}} =
                 FMTP.parse("98 profile-id=1;tier-flag=0;level-id=153;tx-mode=#{tx_mode}")
      end

      assert {:ok, %FMTP{tx_mode: nil}} = FMTP.parse("98 profile-id=1;tier-flag=0;level-id=153")

      assert {:error, :invalid_tx_mode} =
               FMTP.parse("98 profile-id=1;tx-mode=BOGUS")
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

    test "parses proper fmtp with av1 parameters" do
      fmtp = "98 profile=2; level-idx=8; tier=1"

      expected = %FMTP{
        pt: 98,
        profile: 2,
        level_idx: 8,
        tier: 1
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

    test "parses fmtp with mpeg4-generic" do
      fmtp =
        "97 mode=AAC-hbr;config=121056E500;sizelength=13;indexlength=3;constantduration=1024;indexdeltalength=3"

      assert {:ok,
              %FMTP{
                pt: 97,
                mode: :AAC_hbr,
                config: <<18, 16, 86, 229, 0>>,
                sizelength: 13,
                indexlength: 3,
                constantduration: 1024,
                indexdeltalength: 3
              }} = FMTP.parse(fmtp)
    end
  end

  describe "FMTP parameter names" do
    test "are matched whatever their case" do
      for sizelength <- ["sizelength", "sizeLength", "SizeLength", "SIZELENGTH"] do
        fmtp =
          "104 profile-level-id=15; streamtype=5; Mode=AAC-hbr; config=1408;" <>
            "#{sizelength}=13; IndexLength=3; IndexDeltaLength=3;"

        assert {:ok,
                %FMTP{
                  pt: 104,
                  streamtype: 5,
                  mode: :AAC_hbr,
                  config: <<0x14, 0x08>>,
                  sizelength: 13,
                  indexlength: 3,
                  indexdeltalength: 3,
                  unknown: []
                }} = FMTP.parse(fmtp)
      end
    end

    test "are matched whatever their case for video too" do
      assert {:ok, %FMTP{packetization_mode: 1, profile_level_id: 0x42E01F}} =
               FMTP.parse("96 Packetization-Mode=1;PROFILE-LEVEL-ID=42e01f")
    end

    test "written in another case with a value that does not fit are an error" do
      assert {:error, :invalid_mode} = FMTP.parse("97 Mode=20;CBR=64")
      assert {:error, :invalid_mode} = FMTP.parse("97 mode=20")
    end

    test "that are not known are kept as they were written" do
      assert {:ok, %FMTP{unknown: ["DecoderTag=h3c-v3", "X-Custom=AbC"]}} =
               FMTP.parse("96 DecoderTag=h3c-v3;X-Custom=AbC")
    end
  end

  describe "FMTP of mpeg4-generic" do
    test "is parsed when config is written in lower-case hexadecimal" do
      assert {:ok, %FMTP{config: <<0x11, 0xB0>>}} = FMTP.parse("97 mode=AAC-hbr;config=11b0")
      assert {:ok, %FMTP{config: <<0xEB, 0x09, 0x88, 0x00>>}} = FMTP.parse("97 config=eB098800")
    end

    test "is parsed when the mode is spelt in another case or with an underscore" do
      for {mode, expected} <- [
            {"aac-hbr", :AAC_hbr},
            {"AAC-HBR", :AAC_hbr},
            {"AAC_hbr", :AAC_hbr},
            {"aac-lbr", :AAC_lbr},
            {"GENERIC", :generic},
            {"celp-CBR", :CELP_cbr},
            {"Celp-vbr", :CELP_vbr}
          ] do
        assert {:ok, %FMTP{mode: ^expected}} = FMTP.parse("97 mode=#{mode};config=1190")
      end

      assert {:error, :invalid_mode} = FMTP.parse("97 mode=AAC-xbr")
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

    test "serializes tx-mode only when set" do
      base = %FMTP{pt: 98, profile_id: 1, tier_flag: false, level_id: 153}

      assert "#{base}" == "fmtp:98 profile-id=1;tier-flag=0;level-id=153"

      assert "#{%{base | tx_mode: :MRST}}" ==
               "fmtp:98 profile-id=1;tier-flag=0;level-id=153;tx-mode=MRST"
    end

    test "serializes FMTP with sprop-*ps" do
      expected =
        "fmtp:96 profile-space=0;profile-id=1;tier-flag=0;level-id=150;interop-constraints=b00000000000;" <>
          "sprop-vps=QAEMAf//AWAAAAMAAAMAAAMAAAMAlqwJAAAAAQ==;" <>
          "sprop-sps=QgEBAWAAAAMAAAMAAAMAAAMAlqAB4CACHH+KrTuiS7IAAAAB,QgEBAWAAAAMAsAAAAwAAAwCZoAHgIAIcWNrkkUvzcBAQEAg=;" <>
          "sprop-pps=RAHAcvCcFAobJA==,RAHA8vA7NA=="

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

    test "serializes FMTP with bitrate parameter for G7221" do
      fmtp = %FMTP{
        pt: 98,
        bitrate: 48_000
      }

      expected = "fmtp:98 bitrate=48000"

      assert "#{fmtp}" == expected
    end

    test "serializes FMTP with mpeg4-generic fields" do
      fmtp =
        %FMTP{
          pt: 97,
          mode: :AAC_hbr,
          config: <<18, 16, 86, 229, 0>>,
          sizelength: 13,
          indexlength: 3,
          constantduration: 1024,
          indexdeltalength: 3
        }

      assert "#{fmtp}" ==
               "fmtp:97 mode=AAC-hbr;config=121056E500;sizelength=13;indexlength=3;indexdeltalength=3;constantduration=1024"
    end
  end
end

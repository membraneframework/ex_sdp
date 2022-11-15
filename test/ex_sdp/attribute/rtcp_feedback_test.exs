defmodule ExSDP.Attribute.RTCPFeedbackTest do
  use ExUnit.Case, async: true

  alias ExSDP.Attribute.RTCPFeedback

  describe "parse/1" do
    test "basic feedback types" do
      assert RTCPFeedback.parse("* nack") == {:ok, %RTCPFeedback{pt: :all, feedback_type: :nack}}

      assert RTCPFeedback.parse("98 goog-remb") ==
               {:ok, %RTCPFeedback{pt: 98, feedback_type: :remb}}

      assert RTCPFeedback.parse("98 transport-cc") ==
               {:ok, %RTCPFeedback{pt: 98, feedback_type: :twcc}}

      assert RTCPFeedback.parse("98 ccm fir") == {:ok, %RTCPFeedback{pt: 98, feedback_type: :fir}}

      assert RTCPFeedback.parse("98 nack") == {:ok, %RTCPFeedback{pt: 98, feedback_type: :nack}}

      assert RTCPFeedback.parse("98 nack pli") ==
               {:ok, %RTCPFeedback{pt: 98, feedback_type: :pli}}
    end

    test "unknown feedback type" do
      assert RTCPFeedback.parse("96 unknown") ==
               {:ok, %RTCPFeedback{pt: 96, feedback_type: "unknown"}}
    end

    test "invalid inputs" do
      assert RTCPFeedback.parse("all nack") == {:error, :invalid_pt}
      assert RTCPFeedback.parse("-1 nack") == {:error, :invalid_pt}
      assert RTCPFeedback.parse("nack") == {:error, :invalid_rtcp_feedback}
    end
  end

  describe "Serialization (String.Chars protocol)" do
    test "basic feedback types" do
      assert to_string(%RTCPFeedback{pt: :all, feedback_type: :nack}) == "rtcp-fb:* nack"
      assert to_string(%RTCPFeedback{pt: 97, feedback_type: :remb}) == "rtcp-fb:97 goog-remb"
      assert to_string(%RTCPFeedback{pt: 97, feedback_type: :twcc}) == "rtcp-fb:97 transport-cc"
      assert to_string(%RTCPFeedback{pt: 97, feedback_type: :fir}) == "rtcp-fb:97 ccm fir"
      assert to_string(%RTCPFeedback{pt: 97, feedback_type: :nack}) == "rtcp-fb:97 nack"
      assert to_string(%RTCPFeedback{pt: 97, feedback_type: :pli}) == "rtcp-fb:97 nack pli"
    end

    test "Unknown feedback types serialization" do
      assert to_string(%RTCPFeedback{pt: 101, feedback_type: "unknown"}) == "rtcp-fb:101 unknown"
    end
  end
end

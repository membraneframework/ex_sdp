defmodule ExSDP.Attribute.RTCPFeedback do
  @moduledoc """
  This module describes what kind(s) of RTCP Feedback will be used (RFC 4585).

  The example lines that are parsed by this module are (`a=rtcp-fb:` prefix will be handled by `ExSDP.Attribute`)

      a=rtcp-fb:* nack
      a=rtcp-fb:96 goog-remb
      a=rtcp-fb:96 transport-cc
      a=rtcp-fb:96 ccm fir
      a=rtcp-fb:96 nack
      a=rtcp-fb:96 nack pli

  """

  alias ExSDP.Attribute.RTPMapping

  @type t :: %__MODULE__{
          pt: RTPMapping.payload_type_t() | :all,
          feedback_type: feedback_type_t()
        }

  @enforce_keys [:pt, :feedback_type]
  defstruct @enforce_keys

  @typedoc """
  Key that can be used for searching this attribute using `ExSDP.Media.get_attribute/2`.
  """
  @type attr_key :: :rtcp_feedback

  @type feedback_type_t() :: :nack | :fir | :pli | :twcc | :remb | binary()

  @fb_type_mapping %{
    "nack" => :nack,
    "ccm fir" => :fir,
    "nack pli" => :pli,
    "transport-cc" => :twcc,
    "goog-remb" => :remb
  }

  @reverse_fb_type_mapping Map.new(@fb_type_mapping, fn {k, v} -> {v, k} end)

  @spec parse(binary()) :: {:ok, t()}
  def parse(rtcp_fb) do
    [pt_string, rest] = String.split(rtcp_fb, " ", parts: 2)

    pt =
      case pt_string do
        "*" -> :all
        _pt -> String.to_integer(pt_string)
      end

    {:ok, %__MODULE__{pt: pt, feedback_type: parse_feedback_type(rest)}}
  end

  defp parse_feedback_type(fb_type_string) do
    Map.get(@fb_type_mapping, fb_type_string, fb_type_string)
  end

  @spec serialize_feedback_type(feedback_type_t()) :: String.t()
  def serialize_feedback_type(fb_type) when is_binary(fb_type), do: fb_type

  def serialize_feedback_type(fb_type) when is_atom(fb_type) do
    Map.fetch!(@reverse_fb_type_mapping, fb_type)
  end
end

defimpl String.Chars, for: ExSDP.Attribute.RTCPFeedback do
  alias ExSDP.Attribute.RTCPFeedback

  @impl true
  def to_string(%RTCPFeedback{pt: pt, feedback_type: type}) do
    "rtcp-fb:#{pt} #{RTCPFeedback.serialize_feedback_type(type)}"
  end
end

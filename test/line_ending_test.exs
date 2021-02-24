defmodule ExSDP.LineEndingTest do
  use ExUnit.Case
  alias ExSDP

  alias ExSDP.{Origin, Timing}

  @expected_output %ExSDP{
    origin: %Origin{
      address: {10, 47, 16, 5},
      session_id: 2_890_844_526,
      session_version: 2_890_842_807,
      username: "jdoe"
    },
    session_name: "Very fancy session name",
    timing: %Timing{
      start_time: 2_873_397_496,
      stop_time: 2_873_404_696
    },
    version: 0
  }

  describe "ExSDP.parse handles" do
    test "CR line ending" do
      assert {:ok, @expected_output} ==
               "\r"
               |> test_input()
               |> ExSDP.parse()
    end

    test "LF line ending" do
      assert {:ok, @expected_output} ==
               "\n"
               |> test_input()
               |> ExSDP.parse()
    end

    test "CRLF line ending" do
      assert {:ok, @expected_output} ==
               "\r\n"
               |> test_input()
               |> ExSDP.parse()
    end
  end

  describe "ExSDP.parse! handles" do
    test "CR line ending" do
      assert @expected_output ==
               "\r"
               |> test_input()
               |> ExSDP.parse!()
    end

    test "LF line ending" do
      assert @expected_output ==
               "\n"
               |> test_input()
               |> ExSDP.parse!()
    end

    test "CRLF line ending" do
      assert @expected_output ==
               "\r\n"
               |> test_input()
               |> ExSDP.parse!()
    end
  end

  defp test_input(line_ending) do
    base_ending = "\n"

    """
    v=0
    o=jdoe 2890844526 2890842807 IN IP4 10.47.16.5
    s=Very fancy session name
    t=2873397496 2873404696
    """
    |> String.replace(base_ending, line_ending)
  end
end

defmodule ExSDP.WebRTCTest do
  use ExUnit.Case, async: true

  for browser <- ["chromium", "firefox"] do
    test "#{browser} SDP offer" do
      assert {:ok, %ExSDP{}} =
               ExSDP.parse(File.read!("test/fixtures/#{unquote(browser)}_sdp.txt"))
    end
  end
end

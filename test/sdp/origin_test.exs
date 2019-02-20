defmodule Membrane.Protocol.SDP.OriginTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Origin

  describe "Origin parser" do
    test "" do
      assert {:ok, origin} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 10.47.16.5")

      assert origin == %Origin{
               address_type: "IP4",
               network_type: "IN",
               session_id: "2890844526",
               session_version: "2890842807",
               unicast_address: {10, 47, 16, 5},
               username: "jdoe"
             }
    end
  end
end

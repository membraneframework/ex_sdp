defmodule Membrane.Protocol.SDP.OriginTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.{ConnectionData, Origin}

  describe "Origin parser" do
    test "processes valid origin declaration" do
      assert {:ok, origin} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 10.47.16.5")

      assert origin == %Origin{
               session_id: "2890844526",
               address: %ConnectionData.IP4{
                 value: {10, 47, 16, 5}
               },
               session_version: "2890842807",
               username: "jdoe"
             }
    end

    test "username is nil if server does not support it" do
      assert {:ok, origin} = Origin.parse("- 2890844526 2890842807 IN IP4 10.47.16.5")

      assert origin == %Origin{
               session_id: "2890844526",
               address: %ConnectionData.IP4{
                 value: {10, 47, 16, 5}
               },
               session_version: "2890842807",
               username: nil
             }
    end

    test "returns an error if declaration is invalid" do
      assert {:error, :invalid_origin} = Origin.parse("jdoe 2890844526 2890842807")
    end

    test "returns an error if declaration contains not supported address type" do
      assert {:error, :invalid_address} =
               Origin.parse("jdoe 2890844526 2890842807 IN NOTIP 10.47.16.5")
    end

    test "processes origin with FQDN" do
      assert {:ok,
              %Origin{
                address: "host.origin.name",
                session_id: "2890844526",
                session_version: "2890842807",
                username: "jdoe"
              }} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 host.origin.name")
    end
  end

  describe "Origin serializer" do
    test "serializes origin with unknown username" do
      origin = %Origin{session_version: "0", address: "some.origin.address", session_id: "222"}
      assert Origin.serialize(origin) == "o=- 222 0 IN IP4 some.origin.address"
    end

    test "serializes origin with given username" do
      origin = %Origin{
        session_version: "0",
        address: "some.origin.address",
        session_id: "222",
        username: "username_id"
      }

      assert Origin.serialize(origin) == "o=username_id 222 0 IN IP4 some.origin.address"
    end
  end
end

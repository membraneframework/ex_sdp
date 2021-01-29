defmodule ExSDP.OriginTest do
  use ExUnit.Case

  alias ExSDP.Origin

  describe "Origin parser" do
    test "processes valid origin declaration" do
      assert {:ok, origin} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 10.47.16.5")

      assert origin == %Origin{
               session_id: 2_890_844_526,
               address: {10, 47, 16, 5},
               session_version: 2_890_842_807,
               username: "jdoe"
             }
    end

    test "username is nil if server does not support it" do
      assert {:ok, origin} = Origin.parse("- 2890844526 2890842807 IN IP4 10.47.16.5")

      assert origin == %Origin{
               session_id: 2_890_844_526,
               address: {10, 47, 16, 5},
               session_version: 2_890_842_807
             }
    end

    test "returns an error if declaration is invalid" do
      assert {:error, :too_few_fields} = Origin.parse("jdoe 2890844526 2890842807")
    end

    test "returns an error if declaration contains not supported address type" do
      assert {:error, :invalid_addrtype} =
               Origin.parse("jdoe 2890844526 2890842807 IN NOTIP 10.47.16.5")
    end

    test "processes origin with FQDN" do
      assert {:ok,
              %Origin{
                address: {:IP4, "host.origin.name"},
                session_id: 2_890_844_526,
                session_version: 2_890_842_807,
                username: "jdoe"
              }} = Origin.parse("jdoe 2890844526 2890842807 IN IP4 host.origin.name")
    end
  end

  describe "Origin serializer" do
    test "serializes origin" do
      origin = %Origin{
        session_version: 0,
        address: {:IP6, "some.origin.address"},
        session_id: 222,
        username: "username_id"
      }

      assert "#{origin}" == "username_id 222 0 IN IP6 some.origin.address"
    end
  end
end

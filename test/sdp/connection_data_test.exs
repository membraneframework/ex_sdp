defmodule Membrane.Protocol.SDP.ConnectionDataTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.ConnectionData

  describe "Connection information parser when working with ip4" do
    test "parses valid connection with ttl and count params" do
      assert {:ok, connections} = ConnectionData.parse("IN IP4 224.2.1.1/127/3")

      assert connections == [
               %ConnectionData.IP4{
                 ttl: 127,
                 value: {224, 2, 1, 1}
               },
               %ConnectionData.IP4{
                 ttl: 127,
                 value: {224, 2, 1, 2}
               },
               %ConnectionData.IP4{
                 ttl: 127,
                 value: {224, 2, 1, 3}
               }
             ]
    end

    test "parses valid connection with ttl" do
      assert {:ok, connections} = ConnectionData.parse("IN IP4 224.2.1.1/127")

      assert connections == %ConnectionData.IP4{
               ttl: 127,
               value: {224, 2, 1, 1}
             }
    end

    test "parses valid connection " do
      assert {:ok, connections} = ConnectionData.parse("IN IP4 224.2.1.1")

      assert connections == %ConnectionData.IP4{
               ttl: nil,
               value: {224, 2, 1, 1}
             }
    end
  end

  describe "Connection information parser when working with ip6" do
    test "parses valid connection with count param" do
      assert {:ok, connections} = ConnectionData.parse("IN IP6 FF15::101/3")

      assert connections == [
               %ConnectionData.IP6{
                 value: {65_301, 0, 0, 0, 0, 0, 0, 257}
               },
               %ConnectionData.IP6{
                 value: {65_301, 0, 0, 0, 0, 0, 0, 258}
               },
               %ConnectionData.IP6{
                 value: {65_301, 0, 0, 0, 0, 0, 0, 259}
               }
             ]
    end

    test "parses valid connection" do
      assert {:ok, connections} = ConnectionData.parse("IN IP6 FF15::103")

      assert connections == %ConnectionData.IP6{
               value: {65_301, 0, 0, 0, 0, 0, 0, 259}
             }
    end
  end

  describe "Connection information parser returns an error when" do
    test "connection spec is invalid" do
      assert {:error, :invalid_connection_data} = ConnectionData.parse("IN EPI")
    end

    test "address is not valid" do
      assert {:error, :invalid_address} = ConnectionData.parse("IN IP4 224.2.1.1/127/3/4")
    end

    test "either ttl or count is not an integer" do
      assert {:error, :option_nan} = ConnectionData.parse("IN IP4 224.2.1.1/127/3d")
      assert {:error, :option_nan} = ConnectionData.parse("IN IP4 224.2.1.1/127a/3")
    end

    test "ttl is not in 0..255 range" do
      assert {:error, :wrong_ttl} = ConnectionData.parse("IN IP4 224.2.1.1/256")
    end

    test "when address expansion overflows IP octet range" do
      assert {:error, :invalid_address} = ConnectionData.parse("IN IP4 224.2.1.255/127/3")
    end
  end
end

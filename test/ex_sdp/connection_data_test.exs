defmodule ExSDP.ConnectionDataTest do
  use ExUnit.Case

  alias ExSDP.{ConnectionData, Serializer}
  alias ConnectionData.{IP4, IP6}

  describe "Connection information parser when working with ip4" do
    test "parses valid connection with ttl and count params" do
      assert {:ok, connections} = ConnectionData.parse("IN IP4 224.2.1.1/127/3")

      assert connections == [
               %IP4{
                 ttl: 127,
                 value: {224, 2, 1, 1}
               },
               %IP4{
                 ttl: 127,
                 value: {224, 2, 1, 2}
               },
               %IP4{
                 ttl: 127,
                 value: {224, 2, 1, 3}
               }
             ]
    end

    test "parses valid connection with ttl" do
      assert {:ok, connections} = ConnectionData.parse("IN IP4 224.2.1.1/127")

      assert connections == %IP4{
               ttl: 127,
               value: {224, 2, 1, 1}
             }
    end

    test "parses valid connection " do
      assert {:ok, connections} = ConnectionData.parse("IN IP4 224.2.1.1")

      assert connections == %IP4{
               ttl: nil,
               value: {224, 2, 1, 1}
             }
    end
  end

  describe "Connection information parser when working with ip6" do
    test "parses valid connection with count param" do
      assert {:ok, connections} = ConnectionData.parse("IN IP6 FF15::101/3")

      assert connections == [
               %IP6{
                 value: {65_301, 0, 0, 0, 0, 0, 0, 257}
               },
               %IP6{
                 value: {65_301, 0, 0, 0, 0, 0, 0, 258}
               },
               %IP6{
                 value: {65_301, 0, 0, 0, 0, 0, 0, 259}
               }
             ]
    end

    test "parses valid connection" do
      assert {:ok, connections} = ConnectionData.parse("IN IP6 FF15::103")

      assert connections == %IP6{
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

  describe "Connection Data Serializer serializes IPv4" do
    test "address with ttl" do
      assert Serializer.serialize(%IP4{value: {43, 22, 11, 101}, ttl: 3}) ==
               "IN IP4 43.22.11.101/3"
    end

    test "address without ttl" do
      assert Serializer.serialize(%IP4{value: {98, 122, 75, 1}}) == "IN IP4 98.122.75.1"
    end

    test "multiple addresses" do
      data = %ConnectionData{
        addresses: [
          %IP4{value: {28, 0, 0, 1}},
          %IP4{value: {28, 0, 0, 2}},
          %IP4{value: {28, 0, 0, 3}}
        ]
      }

      assert Serializer.serialize(data) == "c=IN IP4 28.0.0.1/3"
    end
  end

  describe "Connection Data Serializer serializes IPv6" do
    test "single address" do
      assert Serializer.serialize(%IP6{value: {43, 0, 0, 0, 1, 1, 11, 101}}) ==
               "IN IP6 2b::1:1:b:65"
    end

    test "multiple addresses" do
      connection_data = %ConnectionData{
        addresses: [
          %IP6{value: {3, 72, 12, 4, 3, 7, 5, 0}},
          %IP6{value: {3, 72, 12, 4, 3, 7, 5, 1}},
          %IP6{value: {3, 72, 12, 4, 3, 7, 5, 2}},
          %IP6{value: {3, 72, 12, 4, 3, 7, 5, 3}},
          %IP6{value: {3, 72, 12, 4, 3, 7, 5, 4}}
        ]
      }

      assert Serializer.serialize(connection_data) == "c=IN IP6 3:48:c:4:3:7:5:0/5"
    end
  end
end

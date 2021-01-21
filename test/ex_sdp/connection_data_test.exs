defmodule ExSDP.ConnectionDataTest do
  use ExUnit.Case

  alias ExSDP.ConnectionData

  describe "Connection information parser when working with ip4" do
    test "parses valid connection with ttl and count params" do
      assert {:ok, connection_data} = ConnectionData.parse("IN IP4 224.2.1.1/127/3")

      assert connection_data == %ConnectionData{
               address: {224, 2, 1, 1},
               address_count: 3,
               ttl: 127,
               network_type: "IN"
             }
    end

    test "parses valid connection with ttl" do
      assert {:ok, connection_data} = ConnectionData.parse("IN IP4 224.2.1.1/127")

      assert connection_data == %ConnectionData{
               ttl: 127,
               address_count: nil,
               address: {224, 2, 1, 1},
               network_type: "IN"
             }
    end

    test "parses valid connection " do
      assert {:ok, connection_data} = ConnectionData.parse("IN IP4 224.2.1.1")

      assert connection_data == %ConnectionData{
               ttl: nil,
               address_count: nil,
               address: {224, 2, 1, 1},
               network_type: "IN"
             }
    end
  end

  describe "Connection information parser when working with ip6" do
    test "parses valid connection with count param" do
      assert {:ok, connection_data} = ConnectionData.parse("IN IP6 FF15::101/3")

      assert connection_data ==
               %ConnectionData{
                 address: {65_301, 0, 0, 0, 0, 0, 0, 257},
                 address_count: 3,
                 ttl: nil,
                 network_type: "IN"
               }
    end

    test "parses valid connection" do
      assert {:ok, connection_data} = ConnectionData.parse("IN IP6 FF15::103")

      assert connection_data == %ConnectionData{
               address: {65_301, 0, 0, 0, 0, 0, 0, 259},
               address_count: nil,
               ttl: nil,
               network_type: "IN"
             }
    end
  end

  describe "Connection information parser returns an error when" do
    test "connection spec is invalid" do
      assert {:error, {:invalid_connection_data, :too_few_fields}} =
               ConnectionData.parse("IN EPI")
    end

    test "address is not valid" do
      assert {:error, {:invalid_connection_data, :invalid_ttl_or_address_count}} =
               ConnectionData.parse("IN IP4 224.2.1.1/127/3/4")
    end

    test "either ttl or count is not an integer" do
      assert {:error, {:invalid_connection_data, :invalid_ttl_or_address_count}} =
               ConnectionData.parse("IN IP4 224.2.1.1/127/3d")

      assert {:error, {:invalid_connection_data, :invalid_ttl_or_address_count}} =
               ConnectionData.parse("IN IP4 224.2.1.1/127a/3")
    end

    test "ttl is not in 0..255 range" do
      assert {:error, {:invalid_connection_data, :invalid_ttl_or_address_count}} =
               ConnectionData.parse("IN IP4 224.2.1.1/256")
    end
  end

  describe "Connection Data Serializer serializes IPv4" do
    test "address with ttl" do
      connection_data = %ConnectionData{address: {43, 22, 11, 101}, ttl: 3}
      assert "#{connection_data}" == "IN IP4 43.22.11.101/3"
    end

    test "address without ttl" do
      connection_data = %ConnectionData{address: {98, 122, 75, 1}}
      assert "#{connection_data}" == "IN IP4 98.122.75.1"
    end

    test "multiple addresses" do
      connection_data = %ConnectionData{
        address: {28, 0, 0, 1},
        address_count: 3
      }

      assert "#{connection_data}" == "IN IP4 28.0.0.1/3"
    end
  end

  describe "Connection Data Serializer serializes IPv6" do
    test "single address" do
      connection_data = %ConnectionData{address: {43, 0, 0, 0, 1, 1, 11, 101}}
      assert "#{connection_data}" == "IN IP6 2b::1:1:b:65"
    end

    test "multiple addresses" do
      connection_data = %ConnectionData{
        address: {3, 72, 12, 4, 3, 7, 5, 0},
        address_count: 5
      }

      assert "#{connection_data}" == "IN IP6 3:48:c:4:3:7:5:0/5"
    end
  end
end

defmodule Membrane.Protocol.SDP.ConnectionInformation.AddressTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.ConnectionInformation.Address

  describe "Address parser proceses IP4" do
    test "valid address" do
      assert {:ok, address} = Address.parse("224.2.1.1")

      assert address == %Address{
               address: {224, 2, 1, 1},
               count: nil,
               ttl: nil
             }
    end

    test "valid address with ttl" do
      assert {:ok, address} = Address.parse("224.2.1.1/3")

      assert address == %Address{
               address: {224, 2, 1, 1},
               count: 3,
               ttl: nil
             }
    end

    test "valid address with ttl and count" do
      assert {:ok, address} = Address.parse("224.2.1.1/127/3")

      assert address == %Address{
               address: {224, 2, 1, 1},
               count: 3,
               ttl: 127
             }
    end
  end

  describe "Address parser proceses IP6" do
    test "valid address" do
      assert {:ok, address} = Address.parse("FF15::101")

      assert address == %Address{
               address: {65301, 0, 0, 0, 0, 0, 0, 257},
               count: nil,
               ttl: nil
             }
    end

    test "valid address with ttl" do
      assert {:ok, address} = Address.parse("FF15::101/3")

      assert address == %Address{
               address: {65301, 0, 0, 0, 0, 0, 0, 257},
               count: 3,
               ttl: nil
             }
    end

    test "valid address with ttl and count" do
      assert {:ok, address} = Address.parse("FF15::101/127/3")

      assert address == %Address{
               address: {65301, 0, 0, 0, 0, 0, 0, 257},
               count: 3,
               ttl: 127
             }
    end
  end

  describe "Adress parser returns an error" do
    test "when address is not valid" do
      assert {:error, :invalid_address} == Address.parse("255.255.255.321")
    end

    test "when there are too many \ in the code" do
      assert {:error, :invalid_address} = Address.parse("FF15::101/127/3/123")
    end

    test "when ttl is not valid integer" do
      assert {:error, :invalid_ttl} = Address.parse("FF15::101/127yup/3")
    end

    test "when count is not valid integer" do
      assert {:error, :invalid_count} = Address.parse("FF15::101/127/3yup")
    end
  end
end

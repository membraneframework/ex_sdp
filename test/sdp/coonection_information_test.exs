defmodule Membrane.Protocol.SDP.ConnectionInformationTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.ConnectionInformation

  describe "Connection information parser" do
    test "parses valid line" do
      assert {:ok, connection} = ConnectionInformation.parse("c=IN IP4 224.2.1.1/127/2")

      assert connection ==
               %Membrane.Protocol.SDP.ConnectionInformation{
                 address: %Membrane.Protocol.SDP.ConnectionInformation.Address{
                   address: {224, 2, 1, 1},
                   count: 2,
                   ttl: 127
                 },
                 address_type: "IP4",
                 network_type: "c=IN"
               }
    end

    test "returns an error if connection spec is invalid" do
      assert {:error, :invalid_connection_information} = ConnectionInformation.parse("c=IN IP4")
    end
  end
end

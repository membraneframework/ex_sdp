defmodule ExSDP.Attribute.MsidTest do
  use ExUnit.Case

  alias ExSDP.Attribute.Msid

  describe "Msid parser" do
    test "parses msid without app data" do
      id = "0YiRg3sIeAEZEhwD3ANvRbn7UFf3BjYBeANS"
      assert {:ok, msid} = Msid.parse(id)
      assert %Msid{id: id} = msid
    end

    test "parses msid with app data" do
      id = "0YiRg3sIeAEZEhwD3ANvRbn7UFf3BjYBeANS"
      app_data = "a60cccca-f708-49e7-89d0-4be0524658a5"
      assert {:ok, msid} = Msid.parse("#{id} #{app_data}")
      assert %Msid{id: id, app_data: app_data} = msid
    end

    test "returns an error when id is empty" do
      app_data = "a60cccca-f708-49e7-89d0-4be0524658a5"
      assert {:error, :invalid_msid} = Msid.parse("")
      assert {:error, :invalid_msid} = Msid.parse(" #{app_data}")
    end
  end

  describe "Msid serializer" do
    test "serializes msid without app data" do
      msid_id = UUID.uuid4()
      msid = Msid.new(msid_id, nil)

      assert "#{msid}" == "msid:#{msid_id}"
    end

    test "serializes msid with app data" do
      id = UUID.uuid4()
      app_data = UUID.uuid4()
      msid = Msid.new(id, app_data)

      assert "#{msid}" == "msid:#{id} #{app_data}"
    end
  end
end

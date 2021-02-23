defmodule ExSDP.Attribute.MSIDTest do
  use ExUnit.Case

  alias ExSDP.Attribute.MSID

  describe "MSID parser" do
    test "parses msid without app data" do
      id = "0YiRg3sIeAEZEhwD3ANvRbn7UFf3BjYBeANS"
      assert {:ok, msid} = MSID.parse(id)
      assert %MSID{id: id} = msid
    end

    test "parses msid with app data" do
      id = "0YiRg3sIeAEZEhwD3ANvRbn7UFf3BjYBeANS"
      app_data = "a60cccca-f708-49e7-89d0-4be0524658a5"
      assert {:ok, msid} = MSID.parse("#{id} #{app_data}")
      assert %MSID{id: id, app_data: app_data} = msid
    end

    test "returns an error when id is empty" do
      app_data = "a60cccca-f708-49e7-89d0-4be0524658a5"
      assert {:error, :invalid_msid} = MSID.parse("")
      assert {:error, :invalid_msid} = MSID.parse(" #{app_data}")
    end
  end

  describe "MSID serializer" do
    test "serializes MSID without app data" do
      msid_id = UUID.uuid4()
      msid = MSID.new(msid_id, nil)

      assert "#{msid}" == "msid:#{msid_id}"
    end

    test "serializes MSID with app data" do
      id = UUID.uuid4()
      app_data = UUID.uuid4()
      msid = MSID.new(id, app_data)

      assert "#{msid}" == "msid:#{id} #{app_data}"
    end
  end
end

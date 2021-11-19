defmodule ExSDP.Attribute.ExtmapTest do
  use ExUnit.Case

  alias ExSDP.Attribute.Extmap

  @test_uri "http://example.com/082005/ext.htm#xmeta"

  describe "Extmap parser" do
    test "parses minimal extmap" do
      extmap = "2 #{@test_uri}"

      expected = %Extmap{
        id: 2,
        uri: @test_uri,
        direction: nil,
        attributes: []
      }

      assert {:ok, expected} == Extmap.parse(extmap)
    end

    test "parses extmap with direction" do
      valid_directions = [:sendonly, :recvonly, :sendrecv, :inactive]

      Enum.each(valid_directions, fn direction ->
        extmap = "2/#{Atom.to_string(direction)} #{@test_uri}"

        expected = %Extmap{
          id: 2,
          uri: @test_uri,
          direction: direction,
          attributes: []
        }

        assert {:ok, expected} == Extmap.parse(extmap)
      end)
    end

    test "parses extmap with attributes" do
      extmap = "2 #{@test_uri} unsigned short int"

      expected = %Extmap{
        id: 2,
        uri: @test_uri,
        direction: nil,
        attributes: ["unsigned", "short", "int"]
      }

      assert {:ok, expected} == Extmap.parse(extmap)
    end

    test "parses extmap with direction and attributes" do
      extmap = "2/sendrecv #{@test_uri} unsigned short int"

      expected = %Extmap{
        id: 2,
        uri: @test_uri,
        direction: :sendrecv,
        attributes: ["unsigned", "short", "int"]
      }

      assert {:ok, expected} == Extmap.parse(extmap)
    end

    test "returns an error when there is invalid id" do
      extmap = "two/sendrecv #{@test_uri} unsigned short int"
      assert {:error, :invalid_id} = Extmap.parse(extmap)

      extmap = "/sendrecv #{@test_uri} unsigned short int"
      assert {:error, :invalid_id} = Extmap.parse(extmap)

      extmap = "sendrecv #{@test_uri} unsigned short int"
      assert {:error, :invalid_id} = Extmap.parse(extmap)
    end

    test "returns an error when there is invalid direction" do
      extmap = "2/invalid #{@test_uri} unsigned short int"
      assert {:error, :invalid_direction} = Extmap.parse(extmap)

      extmap = "2/ #{@test_uri} unsigned short int"
      assert {:error, :invalid_direction} = Extmap.parse(extmap)
    end

    test "returns an error when there is invalid schema" do
      extmap = "invalidschema"
      assert {:error, :invalid_extmap} = Extmap.parse(extmap)
    end
  end

  describe "Extmap serializer" do
    test "serializes minimal extmap" do
      extmap = %Extmap{
        id: 1,
        uri: @test_uri
      }

      assert "#{extmap}" == "extmap:1 #{@test_uri}"
    end

    test "serializes extmap with direction" do
      extmap = %Extmap{
        id: 1,
        uri: @test_uri,
        direction: :sendrecv
      }

      assert "#{extmap}" == "extmap:1/sendrecv #{@test_uri}"
    end

    test "serializes extmap with attributes" do
      extmap = %Extmap{
        id: 1,
        uri: @test_uri,
        attributes: ["unsigned", "short", "int"]
      }

      assert "#{extmap}" == "extmap:1 #{@test_uri} unsigned short int"
    end

    test "serializes extmap with direction and attributes" do
      extmap = %Extmap{
        id: 1,
        uri: @test_uri,
        direction: :sendrecv,
        attributes: ["unsigned", "short", "int"]
      }

      assert "#{extmap}" == "extmap:1/sendrecv #{@test_uri} unsigned short int"
    end
  end
end

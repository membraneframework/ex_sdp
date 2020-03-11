defmodule Membrane.Protocol.SDP.EncryptionTest do
  use ExUnit.Case

  alias Membrane.Protocol.SDP.Encryption

  describe "Encryption parser" do
    test "processes valid method only string" do
      assert {:ok, %Encryption{method: :prompt}} == Encryption.parse("prompt")
    end

    test "processes valid unknown method" do
      assert {:error, :unsupported_method} == Encryption.parse("ask")
    end

    test "processes valid method and uri string" do
      assert {:ok, %Encryption{method: :uri, key: "http://link.to.key"}} ==
               Encryption.parse("uri:http://link.to.key")
    end

    test "processes valid method and base64 key string" do
      key =
        """
        QUFBQUIzTnphQzFRTUtxb1pZRS9KSXZzVHlBQkFBQUJ2QjF6cURMczk4aWVVQW45MXB4SnRJQVJJL0
        1BZDBVNS9IdXVydE9YVVZlZGtJYWMyRUFBQUFEcDkzeDgzYTRFV2tQTDZkMTE4WXdBN0w4OXBweTEz
        THU2Z0FRRFM5RWZWR3NrMkhLTGlEOWJQdVo1VVF4MkFiRXZ0RFp4TzdUQWdGdHFIY2ZpdmsyOEJtdn
        ]pRWXpuRXF4N3d3QU1ZZVI0QXByRnZVbWtQaTgzMUdicXE4Qlg3MDZPd2NFMDRJOXBzSjRoYis4eDZ
        1a2FuWmMrZW1YU2IzYXAzYkJ5YXpPYXlxaS82d2xIYjAxMGQ4SlRCbHRJc2VMak1SQnB5NkhHWTlnb
        TVFZlo0Z0tiUjNENnhob2JxRUhwc0FuS3hOWGQvZUZxVEdkYVJjRmo5NWxqY3VrUTFzZWp0ZHpNeTN
        OSFZhUXgxanY2ZjJvNjJoZm9RUW9uCg==
        """
        |> String.trim()

      assert {:ok, %Encryption{method: :base64, key: result_key}} =
               ("base64:" <> key)
               |> Encryption.parse()

      assert result_key == key
    end
  end

  describe "Encryption serializer" do
    test "serializes encryption description without key" do
      encryption = %Encryption{method: :prompt}
      assert Encryption.serialize(encryption) == "k=prompt"
    end

    test "serializes encryption description with key" do
      encryption = %Encryption{method: :uri, key: "https://some.url.net"}
      assert Encryption.serialize(encryption) == "k=uri:https://some.url.net"
    end
  end
end

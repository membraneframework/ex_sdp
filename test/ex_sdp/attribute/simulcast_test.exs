defmodule ExSDP.Attribute.SimulcastTest do
  use ExUnit.Case, async: true

  alias ExSDP.Attribute.Simulcast

  test "parse/1" do
    assert {:ok, simulcast} = Simulcast.parse("recv l;h;m send l;h")
    assert %Simulcast{recv: ["l", "h", "m"], send: ["l", "h"]} == simulcast

    assert {:ok, simulcast} = Simulcast.parse("send l;h;m")
    assert %Simulcast{recv: [], send: ["l", "h", "m"]} == simulcast

    assert {:ok, simulcast} = Simulcast.parse("send l;m;3 recv 1,2;5")
    assert %Simulcast{recv: [["1", "2"], "5"], send: ["l", "m", "3"]} == simulcast

    assert {:error, :invalid_simulcast} = Simulcast.parse("send l;h,5, rec")
  end

  test "to_string/1" do
    simulcast = %Simulcast{recv: ["l", "h", "m"], send: ["l", "h"]}
    assert to_string(simulcast) == "simulcast:send l;h recv l;h;m"

    simulcast = %Simulcast{recv: [], send: ["l", "h", "m"]}
    assert to_string(simulcast) == "simulcast:send l;h;m"

    simulcast = %Simulcast{recv: [["1", "2"], "5"], send: ["l", "m", "3"]}
    assert to_string(simulcast) == "simulcast:send l;m;3 recv 1,2;5"
  end
end

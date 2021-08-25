defmodule NeedlepointTest do
  use ExUnit.Case

  doctest Needlepoint

  test "Needlepoint.tokenize/1" do
    assert Needlepoint.tokenize("A sentence.") == ["A", "sentence."]
  end

  test "Needlepoint.stem/1" do
    assert Needlepoint.stem("generously") == "generous"
  end
end

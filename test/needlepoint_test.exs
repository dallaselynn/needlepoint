defmodule NeedlepointTest do
  use ExUnit.Case

  doctest Needlepoint

  test "tokenizer defaults to simple" do
    assert Needlepoint.tokenize("A sentence.") == ["A", "sentence."]
  end
end

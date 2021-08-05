defmodule NeedlepointUtilTest do
  use ExUnit.Case

  doctest Needlepoint.Util

  alias Needlepoint.Util

  test "pad_sequence with no opts returns same sequence" do
    assert Util.pad_sequence(["a", "boy", "and", "his", "dog"], 2) == ["a", "boy", "and", "his", "dog"]
  end
end

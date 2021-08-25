defmodule NeedlepointSnowballTest do
  use ExUnit.Case
  alias Needlepoint.Stem.SnowballStemmer

  doctest Needlepoint.Stem.SnowballStemmer

  test "short word returns the word" do
    assert SnowballStemmer.stem("a") == "a"
    assert SnowballStemmer.stem("ab") == "ab"
  end

  test "special snowball word returns the map value" do
    assert SnowballStemmer.stem("skis") == "ski"
    assert SnowballStemmer.stem("succeeding") == "succeed"
  end

  test "stopword returns the word" do
    assert SnowballStemmer.stem("wasn") == "wasn"
    assert SnowballStemmer.stem("their") == "their"
  end

  test "snowball short strings" do
    assert SnowballStemmer.stem("y's") == "y"
  end

  test "generously => generous" do
    assert SnowballStemmer.stem("generously") == "generous"
  end

  test "knit root" do
    assert SnowballStemmer.stem("knit") == "knit"
    assert SnowballStemmer.stem("knits") == "knit"
    assert SnowballStemmer.stem("knitted") == "knit"
    assert SnowballStemmer.stem("knitting") == "knit"
  end

  test "abeyance => abey" do
    assert SnowballStemmer.stem("abeyance") == "abey"
  end

  test "snowball apostrophes" do
    assert SnowballStemmer.stem("'") == "'"
    assert SnowballStemmer.stem("''") == "''"
    assert SnowballStemmer.stem("'a") == "'a"
    assert SnowballStemmer.stem("'''") == "'"
    assert SnowballStemmer.stem("'aa") == "aa"
    assert SnowballStemmer.stem("'as") == "as"
    assert SnowballStemmer.stem("'a'") == "a"
    assert SnowballStemmer.stem("'s'") == "s"
    assert SnowballStemmer.stem("'aa'") == "aa"
    assert SnowballStemmer.stem("'as'") == "as"
    assert SnowballStemmer.stem("a''") == "a'"
    assert SnowballStemmer.stem("aa'") == "aa"
  end
end

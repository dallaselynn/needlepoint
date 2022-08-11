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

  @tag slow: true
  test "all snowball pairs" do
    # list is from http://snowball.tartarus.org/algorithms/english/diffs.txt
    for line <- File.stream!("test/snowball_pairs.txt") do
      [word, stemmed] = String.trim(line) |> String.split
      if word in Needlepoint.stopwords(:snowball) do
        assert SnowballStemmer.stem(word) == word
      else
        assert SnowballStemmer.stem(word) == stemmed
      end
    end
  end
end

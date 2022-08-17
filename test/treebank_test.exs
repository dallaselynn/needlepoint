defmodule TreebankTokenizerTest do
  use ExUnit.Case

  alias Needlepoint.Tokenizer.Treebank

  test "treebank0" do
    assert Treebank.tokenize("A sentence.") == ["A", "sentence", "."]
  end

  test "treebank1" do
    assert Treebank.tokenize(
             "On a $50,000 mortgage of 30 years at 8 percent, the monthly payment would be $366.88."
           ) == [
             "On",
             "a",
             "$",
             "50,000",
             "mortgage",
             "of",
             "30",
             "years",
             "at",
             "8",
             "percent",
             ",",
             "the",
             "monthly",
             "payment",
             "would",
             "be",
             "$",
             "366.88",
             "."
           ]
  end

  test "treebank2" do
    assert Treebank.tokenize("\"We beat some pretty good teams to get here,\" Slocum said.") == [
             "``",
             "We",
             "beat",
             "some",
             "pretty",
             "good",
             "teams",
             "to",
             "get",
             "here",
             ",",
             "''",
             "Slocum",
             "said",
             "."
           ]
  end

  test "treebank3" do
    assert Treebank.tokenize(
             "Well, we couldn't have this predictable, cliche-ridden, \"Touched by an Angel\" (a show creator John Masius worked on) wanna-be if she didn't."
           ) == [
             "Well",
             ",",
             "we",
             "could",
             "n't",
             "have",
             "this",
             "predictable",
             ",",
             "cliche-ridden",
             ",",
             "``",
             "Touched",
             "by",
             "an",
             "Angel",
             "''",
             "(",
             "a",
             "show",
             "creator",
             "John",
             "Masius",
             "worked",
             "on",
             ")",
             "wanna-be",
             "if",
             "she",
             "did",
             "n't",
             "."
           ]
  end

  test "treebank4" do
    assert Treebank.tokenize("I cannot cannot work under these conditions!") == [
             "I",
             "can",
             "not",
             "can",
             "not",
             "work",
             "under",
             "these",
             "conditions",
             "!"
           ]
  end

  test "treebank5" do
    assert Treebank.tokenize("The company spent $30,000,000 last year.") == [
             "The",
             "company",
             "spent",
             "$",
             "30,000,000",
             "last",
             "year",
             "."
           ]
  end

  test "treebank6" do
    assert Treebank.tokenize("The company spent 40.75% of its income last year.") == [
             "The",
             "company",
             "spent",
             "40.75",
             "%",
             "of",
             "its",
             "income",
             "last",
             "year",
             "."
           ]
  end

  test "treebank7" do
    assert Treebank.tokenize("He arrived at 3:00 pm.") == [
             "He",
             "arrived",
             "at",
             "3:00",
             "pm",
             "."
           ]
  end

  test "treebank8" do
    assert Treebank.tokenize("I bought these items: books, pencils, and pens.") == [
             "I",
             "bought",
             "these",
             "items",
             ":",
             "books",
             ",",
             "pencils",
             ",",
             "and",
             "pens",
             "."
           ]
  end

  test "treebank9" do
    assert Treebank.tokenize("Though there were 150, 100 of them were old.") == [
             "Though",
             "there",
             "were",
             "150",
             ",",
             "100",
             "of",
             "them",
             "were",
             "old",
             "."
           ]
  end

  test "treebank10" do
    assert Treebank.tokenize("There were 300,000, but that wasn't enough.") == [
             "There",
             "were",
             "300,000",
             ",",
             "but",
             "that",
             "was",
             "n't",
             "enough",
             "."
           ]
  end

  test "treebank11" do
    assert Treebank.tokenize("It's more'n enough.") == ["It", "'s", "more", "'n", "enough", "."]
  end
end

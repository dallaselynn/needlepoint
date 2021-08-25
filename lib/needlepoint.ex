defmodule Needlepoint do
  @moduledoc """
  NLP Experiments With Elixir

  The `Needlepoint` library is a collection of NLP
  functions for Elixir using the `Nx` library
  ecosystem.
  """

  @doc """
  Tokenize with a given tokenizer.  Defaults to treebank.

  ## Examples

      iex> alias Needlepoint.Tokenizer.Treebank
      iex> Needlepoint.tokenize("A sentence of words.", Treebank)
      ["A", "sentence", "of", "words", "."]

  """

  def tokenize(text, tokenizer \\ Needlepoint.Tokenizer.Simple, opts \\ []) do
    tokenizer.tokenize(text, opts)
  end

  def stem(text, stemmer \\ Needlepoint.Stem.SnowballStemmer) do
    stemmer.stem(text)
  end

  # TODO: make a spec - corpus is an atom.
  # make or document a list of possible corpus choices
  # is corpus a good name for this variable?
  def stopwords(), do: stopwords(:nltk)
  def stopwords(corpus), do: Needlepoint.Stopwords.words(corpus)
end

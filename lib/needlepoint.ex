defmodule Needlepoint do
  @moduledoc """
  NLP Experiments With Elixir

  The `Needlepoint` library is a collection of NLP functions for Elixir, generally ported
  from sPacy or NLTK Python libraries.
  """

  @doc """
  Tokenize with a given tokenizer.  Defaults to treebank.

  ## Examples

      iex> Needlepoint.tokenize("A sentence of words.")
      ["A", "sentence", "of", "words", "."]
  """
  @spec tokenize(String.t(), module(), []) :: [String.t()]
  def tokenize(text, tokenizer \\ Needlepoint.Tokenizer.Treebank, opts \\ []) do
    tokenizer.tokenize(text, opts)
  end

  @doc """
  Stem with a given stemmer.  Defaults to snowball.

  ## Examples

      iex> Needlepoint.stem("sentence")
      "sentenc"
  """
  @spec stem(String.t(), module()) :: String.t()
  def stem(text, stemmer \\ Needlepoint.Stem.SnowballStemmer) do
    stemmer.stem(text)
  end

  @doc false
  def stopwords(), do: stopwords(:nltk)
  @doc false
  @spec stopwords(:nltk | :snowball) :: [String.t()]
  def stopwords(corpus), do: Needlepoint.Stopwords.words(corpus)
end

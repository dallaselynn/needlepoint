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

  def tokenize(text, tokenizer \\ Needlepoint.Tokenizer.Simple) do
    tokenizer.tokenize(text)
  end
end

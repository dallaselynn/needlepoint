defmodule Needlepoint.Tokenizer do
  @moduledoc """
  The behaviour for tokenizing.

  Tokenization is taking a string and breaking it into
  pieces (`tokens`)
  """

  @callback tokenize(String.t, Keyword.t) :: [String.t]
end

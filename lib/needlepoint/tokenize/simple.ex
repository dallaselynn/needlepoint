defmodule Needlepoint.Tokenizer.Simple do
  @behaviour Needlepoint.Tokenizer

  def tokenize(s, _opts \\ []), do: String.split(s)
end

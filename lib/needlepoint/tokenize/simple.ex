defmodule Needlepoint.Tokenizer.Simple do
  @moduledoc """
  A simple tokenizer that just splits the input with `String.split`
  """

  @behaviour Needlepoint.Tokenizer

  @impl Needlepoint.Tokenizer
  def tokenize(s, _opts \\ []), do: String.split(s)
end

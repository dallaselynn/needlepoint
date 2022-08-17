defmodule Needlepoint.Stemmer do
  @moduledoc """
  A processing interface for removing morphological affixes from words.  This process is known as stemming.
  """

  @callback stem(String.t()) :: String.t()
end

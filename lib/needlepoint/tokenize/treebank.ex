defmodule Needlepoint.Tokenizer.Treebank do
  @moduledoc """
  A port of the NLTK Treebank Tokenizer.
  """
  @behaviour Needlepoint.Tokenizer

  @starting_quotes [
    [~r/^"/, "``"],
    [~r/(``)/, " \\1 "],
    [~r/([ \\(\\[\\{<])("|'{2})/, "\\1 `` "]
  ]

  @punctuation [
    [~r/([:,])([^\d])/, " \\1 \\2"],
    [~r/([:,])$/, " \\1 "],
    [~r/\.\.\./, " ... "],
    [~r/[;@\\#\\$%&]/, " \\g{0} "],
    [~r/([^\.])(\.)([\]\)}>"']*)\s*$/, "\\1 \\2\\3 "], # Handles the final period.
    [~r/[?!]/, " \\g{0} "],
    [~r/([^'])' /, "\\1 ' "],
  ]

  @parens_brackets [[~r/[\]\[\(\)\{\}<>]/, " \\g{0} "]]

  @convert_parentheses [
    [~r/\(/, "-LRB-"],
    [~r/\)/, "-RRB-"],
    [~r/\[/, "-LSB-"],
    [~r/\]/, "-RSB-"],
    [~r/\{/, "-LCB-"],
    [~r/\}/, "-RCB-"],
  ]

  @double_dashes [[~r/--/, " -- "]]

  @ending_quotes [
    [~r/"/, " '' "],
    [~r/(\S)(\'\')/, "\\1 \\2 "],
    [~r/([^' ])('[sS]|'[mM]|'[dD]|') /, "\\1 \\2 "],
    [~r/([^' ])('ll|'LL|'re|'RE|'ve|'VE|n't|N'T) /, "\\1 \\2 "],
  ]

  @macintyre_contractions [
    [~r/(?i)\b(can)(?#X)(not)\b/, " \\1 \\2 "],
    [~r/(?i)\b(d)(?#X)('ye)\b/, " \\1 \\2 "],
    [~r/(?i)\b(gim)(?#X)(me)\b/, " \\1 \\2 "],
    [~r/(?i)\b(gon)(?#X)(na)\b/, " \\1 \\2 "],
    [~r/(?i)\b(got)(?#X)(ta)\b/, " \\1 \\2 "],
    [~r/(?i)\b(lem)(?#X)(me)\b/, " \\1 \\2 "],
    [~r/(?i)\b(more)(?#X)('n)\b/, " \\1 \\2 "],
    [~r/(?i)\b(wan)(?#X)(na)\s/, " \\1 \\2 "],
    [~r/(?i) ('t)(?#X)(is)\b/, " \\1 \\2 "],
    [~r/(?i) ('t)(?#X)(was)\b/, " \\1 \\2 "],
  ]

  def tokenize(text, opts \\ []) do
    convert_parentheses? = Keyword.get(opts, :convert_parentheses, false)

    text
      |> substitute(@starting_quotes)
      |> substitute(@punctuation)
      |> substitute(@parens_brackets)
      |> substitute(@convert_parentheses, convert_parentheses?)
      |> substitute(@double_dashes)
      |> then(&(" " <> &1 <> " "))
      |> substitute(@ending_quotes)
      |> substitute(@macintyre_contractions)
      |> String.split()
  end

  defp substitute(text, regexes), do: substitute(text, regexes, true)
  defp substitute(text, _regexes, false), do: text
  defp substitute(text, regexes, true) do
    Enum.reduce(regexes, text, fn x, text -> Regex.replace(Enum.at(x,0), text, Enum.at(x,1)) end)
  end
end

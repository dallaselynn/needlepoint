defmodule Needlepoint.Util do
  @doc """
    Returns a padded sequence of items before ngram extraction.

  ## Examples

      iex> alias Needlepoint.Util
      Needlepoint.Util
      iex> Util.pad_sequence([1,2,3,4,5], 2)
      [1, 2, 3, 4, 5]
      iex> Util.pad_sequence([2,3,4,5,6], 3, pad_left: true, pad_right: true)
      [nil, nil, 2, 3, 4, 5, 6, nil, nil]
      iex> Util.pad_sequence([3,4,5,6,7], 2, pad_left: true, pad_right: true, left_pad_symbol: "<s>", right_pad_symbol: "</s>")
      ["<s>", 3, 4, 5, 6, 7, "</s>"]
      iex> Util.pad_sequence([4,5,6,7,8], 2, pad_left: true, left_pad_symbol: "<s>")
      ["<s>", 4, 5, 6, 7, 8]
      iex> Util.pad_sequence([5,6,7,8,9], 2, pad_right: true, right_pad_symbol: "</s>")
      [5, 6, 7, 8, 9, "</s>"]
  """
  # TODO: should this return a stream like the nltk version converts to an interator?
  def pad_sequence(sequence, n), do: pad_sequence(sequence, n, [])
  def pad_sequence(sequence, _n, opts) when length(opts) == 0, do: sequence
  def pad_sequence(sequence, n, opts) do
    pad_left = Keyword.get(opts, :pad_left, false)
    pad_right = Keyword.get(opts, :pad_right, false)

    s1 =
      if pad_left do
        List.duplicate(Keyword.get(opts, :left_pad_symbol), n-1) ++ sequence
      else
        sequence
      end

    if pad_right do
      s1 ++ List.duplicate(Keyword.get(opts, :right_pad_symbol), n-1)

    else
      s1
    end
  end

  @doc """
  Return the ngrams generated from a sequence of items, as a stream.

  ## Examples

      iex> Needlepoint.Util.ngrams([1,2,3,4,5], 3) |> Enum.to_list()
      [[1, 2, 3], [2, 3, 4], [3, 4, 5]]

      iex> Needlepoint.Util.ngrams([1,2,3,4,5], 2, pad_right: true) |> Enum.to_list()
      [[1, 2], [2, 3], [3, 4], [4, 5], [5, nil]]

      iex> Needlepoint.Util.ngrams([1,2,3,4,5], 2, pad_right: true, right_pad_symbol: "</s>") |> Enum.to_list()
      [[1, 2], [2, 3], [3, 4], [4, 5], [5, "</s>"]]

      iex> Needlepoint.Util.ngrams([1,2,3,4,5], 2, pad_left: true, left_pad_symbol: "<s>") |> Enum.to_list()
      [["<s>", 1], [1, 2], [2, 3], [3, 4], [4, 5]]

      iex> Needlepoint.Util.ngrams([1,2,3,4,5], 2, pad_left: true, pad_right: true, left_pad_symbol: "<s>", right_pad_symbol: "</s>") |> Enum.to_list()
      [["<s>", 1], [1, 2], [2, 3], [3, 4], [4, 5], [5, "</s>"]]
  """
  def ngrams(sequence, n), do: ngrams(sequence, n, [])
  def ngrams(sequence, n, opts) do
    sequence
      |> pad_sequence(n, opts)
      |> Stream.chunk_every(n, 1, :discard)
  end


  @doc """
  Check if a string is uppercased.

  ## Examples

      iex> Needlepoint.Util.is_upcase?("foo")
      false

      iex> Needlepoint.Util.is_upcase?("FOo")
      false

      iex> Needlepoint.Util.is_upcase?("FOO")
      true
  """
  def is_upcase?(word), do: String.upcase(word) == word

  @doc """
  Check if a string is downcased.

  ## Examples

      iex> Needlepoint.Util.is_downcase?("foo")
      true

      iex> Needlepoint.Util.is_downcase?("FOo")
      false

      iex> Needlepoint.Util.is_downcase?("FOO")
      false
  """
  def is_downcase?(word), do: String.downcase(word) == word


  @doc """
  Take the product of 2 enumerables, a simple version of
  Python's itertools.product

  ## Examples
      iex> Needlepoint.Util.product([],[])
      []

      iex> Needlepoint.Util.product(["a","b"], ["x","y","z"])
      [["a", "x"], ["a", "y"], ["a", "z"], ["b", "x"], ["b", "y"], ["b", "z"]]
  """
  def product(a,b) do
    for x <- a, y <- b, do: [x, y]
  end

end

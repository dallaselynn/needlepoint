defmodule Needlepoint.Probability.FreqDist do
  @moduledoc """
  A frequency distribution for the outcomes of an experiment.

  This basically just adds some functions for use with `Enum.frequencies`

  Based on the NLTK class which is a subclass of the Counter
  in Python's collections class, sometimes called a bag
  or multiset.

  ## Examples

      iex> alias Needlepoint.Probability.FreqDist

      iex> FreqDist.new()
      %Needlepoint.Probability.FreqDist{samples: %{}}

      iex> FreqDist.new("abracadabra")
      %Needlepoint.Probability.FreqDist{
          samples: %{"a" => 5, "b" => 2, "c" => 1, "d" => 1, "r" => 2}
      }

      iex> FreqDist.new("ABCABC") |> FreqDist.elements() |> Enum.sort() |> Enum.join()
      "AABBCC"

      iex> FreqDist.new("abracadabra") |> FreqDist.most_common()
      [{"a", 5}, {"r", 2}, {"b", 2}, {"d", 1}, {"c", 1}]

      iex> FreqDist.new("abracadabra") |> FreqDist.most_common(3)
      [{"a", 5}, {"r", 2}, {"b", 2}]

      iex> FreqDist.new("abracadabra") |> FreqDist.update("simsalabim") |> FreqDist.most_common()
      [
        {"a", 7},
        {"b", 3},
        {"s", 2},
        {"r", 2},
        {"m", 2},
        {"i", 2},
        {"l", 1},
        {"d", 1},
        {"c", 1}
      ]

      iex> FreqDist.new("abracadabra") |> FreqDist.subtract("aaaaa")
      %Needlepoint.Probability.FreqDist{
          samples: %{"a" => 0, "b" => 2, "c" => 1, "d" => 1, "r" => 2}
      }

  """
  alias __MODULE__

  # samples are stored like key => count
  defstruct samples: %{}
  @type t :: %__MODULE__{samples: map()}

  @doc "Make a new empty `FreqDict`"
  def new(), do: %FreqDist{}

  @doc """
  Make a new `FreqDict` from a string, list, map or another `FreqDist`

  ## Examples

      iex> FreqDist.new("gallahad")
      %Needlepoint.Probability.FreqDist{
          samples: %{"a" => 3, "d" => 1, "g" => 1, "h" => 1, "l" => 2}
      }

      iex> FreqDist.new(%{"a" => 4, "b" => 2})
      %Needlepoint.Probability.FreqDist{samples: %{"a" => 4, "b" => 2}}

      iex> FreqDist.new(["a","a","a","a","b","b"])
      %Needlepoint.Probability.FreqDist{samples: %{"a" => 4, "b" => 2}}

  """
  def new(samples) when is_binary(samples) do
    samples = samples |> String.graphemes |> Enum.frequencies

    %FreqDist{samples: samples}
  end
  def new(%FreqDist{} = fd), do: %FreqDist{samples: fd.samples}
  def new(samples) when is_map(samples), do: %FreqDist{samples: samples}
  def new(samples), do: %FreqDist{samples: samples |> Enum.frequencies}

  @doc """
  List all counts from the most common to the least.

  ## Examples

      iex> alias Needlepoint.Probability.FreqDist
      Needlepoint.Probability.FreqDist
      iex> FreqDist.new("aabbbcccddddd") |> FreqDist.most_common()
      [{"d", 5}, {"c", 3}, {"b", 3}, {"a", 2}]
  """
  def most_common(%FreqDist{} = fd), do: Enum.sort(fd.samples, &(elem(&1,1) > elem(&2,1)))


  @doc """
  List n counts from the most common to the least.

  ## Examples

      iex> alias Needlepoint.Probability.FreqDist
      Needlepoint.Probability.FreqDist
      iex> FreqDist.new("aabbbcccddddd") |> FreqDist.most_common(1)
      [{"d", 5}]
  """
  def most_common(%FreqDist{} = fd, n), do: most_common(fd) |> Enum.take(n)

  @doc """
  Iterate over elements repeating each as many times as its count.

  ## Examples

      iex> FreqDist.new("ABCABC") |> FreqDist.elements() |> Enum.sort()
      ["A", "A", "B", "B", "C", "C"]

      # Knuth's example for prime factors of 1836:  2**2 * 3**3 * 17**1
      iex> FreqDist.new(%{2 => 2, 3 => 3, 17 => 1}) |> FreqDist.elements() |> Enum.reduce(1, fn x, acc -> x * acc end)
      1836


  Note, if an element's count has been set to zero or is a negative number, `elements()` will ignore it.
  """
  def elements(%FreqDist{} = fd) do
    Enum.map(fd.samples, fn {key,count} -> List.duplicate(key, count) end) |> List.flatten
  end

  @doc """
  Update the FreqDict `fd` with the new set of samples.

  ## Examples

      iex> alias Needlepoint.Probability.FreqDist
      Needlepoint.Probability.FreqDist
      iex> FreqDist.new("aaa") |> FreqDist.update("bbb")
      %Needlepoint.Probability.FreqDist{samples: %{"a" => 3, "b" => 3}}

  """
  def update(%FreqDist{} = fd, samples) do
    fd2 = FreqDist.new(samples)
    Map.merge(fd.samples, fd2.samples, fn _k, v1, v2 -> v1 + v2 end)
    |> FreqDist.new()
  end

  @doc """
  Update the FreqDict `fd` by subtracting values in the samples.

  ## Examples

      iex> FreqDist.new("aaabbb") |> FreqDist.subtract(FreqDist.new("aba"))
      %Needlepoint.Probability.FreqDist{samples: %{"a" => 1, "b" => 2}}
  """
  def subtract(%FreqDist{} = fd, samples) do
    fd2 = FreqDist.new(samples)

    Map.merge(fd.samples, fd2.samples, fn _k, v1, v2 -> v1 - v2 end)
    |> FreqDist.new()
  end

  @doc """
  union is the maximum of value in either of the input counters.

  ## Examples

      iex> FreqDist.new("abbb") |> FreqDist.union(FreqDist.new("bcc"))
      %Needlepoint.Probability.FreqDist{samples: %{"a" => 1, "b" => 3, "c" => 2}}
  """
  def union(%FreqDist{} = fd, samples) do
    fd2 = FreqDist.new(samples)

    Map.merge(fd.samples, fd2.samples, fn _k, v1, v2 -> Enum.max([v1, v2]) end)
    |> FreqDist.new()
  end

  @doc """
  intersection is the minimum of corresponding counts.

  Values that only appear in one count are dropped.

  ## Examples

      iex> FreqDist.new("abbb") |> FreqDist.intersection(FreqDist.new("bcc"))
      %Needlepoint.Probability.FreqDist{samples: %{"b" => 1}}
  """
  def intersection(%FreqDist{} = fd, samples) do
    fd2 = FreqDist.new(samples)

    common =
      MapSet.new(Map.keys(fd.samples))
      |> MapSet.intersection(MapSet.new(Map.keys(fd2.samples)))
      |> MapSet.to_list()

    Map.merge(
      Map.take(fd.samples, common),
      Map.take(fd2.samples, common),
      fn _k, v1, v2 -> min(v1,v2) end
    )
    |> FreqDist.new()
  end

  @doc """
  Return the total number of sample outcomes that have been recorded.

  ## Examples

      iex> FreqDist.n(FreqDist.new("aabbccdd"))
      8
  """
  def n(%FreqDist{} = fd) do
    Enum.sum(Map.values(fd.samples))
  end

  @doc """
  Return the total number of sample values ("bins") that have counts greater than zero.
  Called `B` in nltk.

  ## Examples

      iex> FreqDist.bins(FreqDist.new(%{"a" => 0, "b" => 1}))
      1
  """
  def bins(%FreqDist{} = fd) do
    length(Enum.filter(Map.values(fd.samples), &(&1 > 0)))
  end


  @doc """
  Return a list of all samples that occur once (hapax legomena)

  ## Examples

      iex> FreqDist.hapaxes(FreqDist.new(%{"a" => 0, "b" => 1, "c" => 2}))
      ["b"]
  """
  def hapaxes(%FreqDist{} = fd) do
    fd.samples
      |> Enum.filter(fn {_,v} -> v == 1 end)
      |> Map.new
      |> Map.keys
  end

  @doc """
  Return the dictionary mapping r to Nr, the number of samples with frequency r, where Nr > 0.

  ## Examples

      iex> FreqDist.r_nr(FreqDist.new(%{"a" => 0, "b" => 1, "c" => 2, "d" => 2}))
      %{0 => 1, 1 => 1, 2 => 2}
  """
  def r_nr(%FreqDist{} = fd) do
    fd.samples
    |> Map.values()
    |> Enum.reduce(Map.new, fn x,acc -> Map.update(acc, x, 1, fn existing -> existing + 1 end) end)
  end

  @doc """
  Return the frequency of a given sample.

  The frequency of a sample is defined as the count of that sample divided by the
  total number of sample outcomes that have been recorded by
  this FreqDist.  The count of a sample is defined as the number of times that
  sample outcome was recorded by this `FreqDist`.

  Frequencies are always real numbers in the range [0, 1]

  ## Examples

      iex> FreqDist.freq(FreqDist.new(%{"a" => 0, "b" => 1, "c" => 2, "d" => 2}), "z")
      0.0

      iex> FreqDist.freq(FreqDist.new(%{"a" => 0, "b" => 1, "c" => 2, "d" => 2}), "a")
      0.0

      iex> FreqDist.freq(FreqDist.new(%{"a" => 0, "b" => 1, "c" => 2, "d" => 2}), "b")
      0.2
  """
  def freq(%FreqDist{} = fd, sample) do
    n = FreqDist.n(fd)
    cond do
      n == 0 -> 0
      n -> Map.get(fd.samples, sample, 0) / n
    end
  end

  @doc """
  Return the sample with the greatest number of outcomes.

  If two or more samples have the same number of outcomes,
  return one of them; which sample is returned is undefined.

  If no outcomes have occurred in this frequency distribution, return nil.

  ## Examples

      iex> FreqDist.max(FreqDist.new())
      nil

      iex> FreqDist.max(FreqDist.new(%{"a" => 0, "b" => 1, "c" => 2}))
      "c"
  """
  def max(%FreqDist{} = fd) do
    try do
      {sample, _count} = Enum.max_by(fd.samples, fn {_x,y} -> y end)
      sample
    rescue
      Enum.EmptyError -> nil
    end
  end
end

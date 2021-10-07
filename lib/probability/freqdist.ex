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

    iex> FreqDist.new("abracadabra") |> FreqDist.update("simsalabim") |> FreqDist.most_common
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


  @doc "List all counts from the most common to the least."
  def most_common(%FreqDist{} = fd), do: Enum.sort(fd.samples, &(elem(&1,1) > elem(&2,1)))
  @doc "List n counts from the most common to the least."
  def most_common(%FreqDist{} = fd, n), do: most_common(fd) |> Enum.take(n)

  @doc """
  Iterate over elements repeating each as many times as its count.

  ## Examples
    iex> FreqDist.new("ABCABC") |> FreqDist.elements() |> Enum.sort()
    ["A", "A", "B", "B", "C", "C"]

    # Knuth's example for prime factors of 1836:  2**2 * 3**3 * 17**1
    iex> prime_factors = FreqDist.new(%{2 => 2, 3 => 3, 17 => 1})
    %Needlepoint.Probability.FreqDist{samples: %{2 => 2, 3 => 3, 17 => 1}}
    iex> Enum.reduce(FreqDist.elements(prime_factors), 1, fn x, acc -> x * acc end)
    1836

    Note, if an element's count has been set to zero or is a negative
    number, elements() will ignore it.
  """
  def elements(%FreqDist{} = fd) do
    Enum.map(fd.samples, fn {key,count} -> List.duplicate(key, count) end) |> List.flatten
  end

  @doc """
  Update the FreqDict `fd` with the new set of samples.
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
end

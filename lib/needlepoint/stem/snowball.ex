defmodule Needlepoint.Stem.SnowballStemmer do
  @moduledoc """
  A port of the NLTK version of the snowball stemmer, as described at
  http://snowball.tartarus.org/algorithms/english/stemmer.html

  If calling this directly instead of from `Needlepoint.stem` the word given to stem
  should be lowercased or else special word and stop words will be stemmed instead of
  returned.
  """

  @behaviour Needlepoint.Stemmer

  @special_words %{
    "skis" => "ski",
    "skies" => "sky",
    "dying" => "die",
    "lying" => "lie",
    "tying" => "tie",
    "idly" => "idl",
    "gently" => "gentl",
    "ugly" => "ugli",
    "early" => "earli",
    "only" => "onli",
    "singly" => "singl",
    "sky" => "sky",
    "news" => "news",
    "howe" => "howe",
    "atlas" => "atlas",
    "cosmos" => "cosmos",
    "bias" => "bias",
    "andes" => "andes",
    "inning" => "inning",
    "innings" => "inning",
    "outing" => "outing",
    "outings" => "outing",
    "canning" => "canning",
    "cannings" => "canning",
    "herring" => "herring",
    "herrings" => "herring",
    "earring" => "earring",
    "earrings" => "earring",
    "proceed" => "proceed",
    "proceeds" => "proceed",
    "proceeded" => "proceed",
    "proceeding" => "proceed",
    "exceed" => "exceed",
    "exceeds" => "exceed",
    "exceeded" => "exceed",
    "exceeding" => "exceed",
    "succeed" => "succeed",
    "succeeds" => "succeed",
    "succeeded" => "succeed",
    "succeeding" => "succeed"
  }

  @vowels ~w(a e i o u y)
  @double_consanants ~w(bb dd ff gg mm nn pp rr tt)
  @valid_li_ending ~w(c d e g h k m n r t)
  @special_form_prefixes ~w(gener arsen commun)
  @stopwords Needlepoint.stopwords(:snowball)
  @step0_suffixes ~w('s' 's ')
  @step1a_suffixes ~w(sses ied ies us ss s)
  @step1b_suffixes ~w(eedly ingly edly eed ing ed)
  @step2_suffixes ~w(
    ization ational fulness ousness iveness tional biliti
    lessli entli ation alism aliti ousli iviti fulli
    enci anci abli izer ator alli bli ogi li
  )
  @step3_suffixes ~w(ational tional alize icate iciti ative ical ness ful)
  @step4_suffixes ~w(ement ance ence able ible ment ant ent ism ate iti ous ive ize ion al er ic)

  @doc """
    Stem the word with the snowball stemmer.  Currently there is no option to
    ignore stopwords like the nltk version.

    ## Examples

      iex> alias Needlepoint.Stem.SnowballStemmer
      iex> SnowballStemmer.stem("running")
      "run"
      iex> SnowballStemmer.stem("abeyance")
      "abey"
  """
  def stem(word) when word in @stopwords, do: word
  def stem(word) when is_map_key(@special_words, word), do: Map.fetch!(@special_words, word)
  def stem(word), do: if(String.length(word) <= 2, do: word, else: snowball(word))

  defp snowball(word) do
    # the initial steps just modify the word, these take and return a word.
    word =
      word
      |> normalize_apostrophes()
      |> skip_leading_apostrophe()
      |> capitalize_y()

    {r1, r2} = initialize_regions(word)

    {stem, _, _} =
      {word, r1, r2}
      |> step0()
      |> step1a()
      |> step1b()
      |> step1c()
      |> step2()
      |> step3()
      |> step4()
      |> step5()

    String.replace(stem, "Y", "y")
  end

  defp normalize_apostrophes(word),
    do: String.replace(word, ~r/[\x{2019}\x{2018}\x{201B}]/u, "\x27")

  defp skip_leading_apostrophe(word) do
    if String.starts_with?(word, "\x27") do
      String.slice(word, 1..-1)
    else
      word
    end
  end

  # "Set initial y, or y after a vowel, to Y"
  defp capitalize_y(word) do
    word
    |> String.graphemes()
    |> Enum.with_index()
    |> Enum.map_join(
      "",
      fn
        {"y", 0} ->
          "Y"

        {"y", idx} ->
          if String.at(word, idx - 1) in @vowels do
            "Y"
          else
            "y"
          end

        {letter, _idx} ->
          letter
      end
    )
  end

  defp is_special_form?(word), do: String.starts_with?(word, @special_form_prefixes)

  # Define a short syllable in a word as either (a) a vowel followed by a non-vowel other than w, x or Y
  # and preceded by a non-vowel, or * (b) a vowel at the beginning of the word followed by a non-vowel.
  defp has_short_syllable?(word, r1) do
    (String.length(r1) == 0 and
       String.length(word) >= 3 and
       String.at(word, -1) not in @vowels and
       not String.contains?(String.at(word, -1), ["w", "x", "Y"]) and
       String.at(word, -2) in @vowels and
       String.at(word, -3) not in @vowels) or
      (String.length(r1) == 0 and
         String.length(word) == 2 and
         String.at(word, 0) in @vowels and
         String.at(word, 1) not in @vowels)
  end

  # for some string - return index or nil
  defp first_non_vowel_following_vowel(word) do
    Enum.to_list(1..(String.length(word) - 1))
    |> Enum.find(fn x ->
      String.at(word, x) not in @vowels and String.at(word, x - 1) in @vowels
    end)
  end

  defp region_after_first_non_vowel_following_vowel(word) do
    case first_non_vowel_following_vowel(word) do
      nil -> ""
      idx -> String.slice(word, (idx + 1)..-1)
    end
  end

  defp first_suffix_match(word, suffixes),
    do: Enum.find(suffixes, fn x -> String.ends_with?(word, x) end)

  defp strip_first_suffix_match(word, suffixes) do
    Enum.reduce_while(suffixes, word, fn x, acc ->
      if String.ends_with?(acc, x),
        do: {:halt, String.replace_suffix(acc, x, "")},
        else: {:cont, acc}
    end)
  end

  defp initialize_r1(word, is_special_form)

  defp initialize_r1(word, true) do
    cond do
      String.starts_with?(word, ["gener", "arsen"]) -> String.slice(word, 5..-1)
      String.starts_with?(word, "commun") -> String.slice(word, 6..-1)
    end
  end

  defp initialize_r1(word, false), do: region_after_first_non_vowel_following_vowel(word)

  defp initialize_regions(word) do
    r1 = initialize_r1(word, is_special_form?(word))
    r2 = region_after_first_non_vowel_following_vowel(r1)

    {r1, r2}
  end

  defp step0({word, r1, r2}) do
    {
      strip_first_suffix_match(word, @step0_suffixes),
      strip_first_suffix_match(r1, @step0_suffixes),
      strip_first_suffix_match(r2, @step0_suffixes)
    }
  end

  defp step1a({word, r1, r2}) do
    case first_suffix_match(word, @step1a_suffixes) do
      "sses" ->
        {String.slice(word, 0..-3), String.slice(r1, 0..-3), String.slice(r2, 0..-3)}

      suffix when suffix in ["ied", "ies"] ->
        if String.length(word) - 3 > 1 do
          {String.slice(word, 0..-3), String.slice(r1, 0..-3), String.slice(r2, 0..-3)}
        else
          {String.slice(word, 0..-2), String.slice(r1, 0..-2), String.slice(r2, 0..-2)}
        end

      "s" ->
        case String.slice(word, 0..-3)
             |> String.graphemes()
             |> Enum.find(fn x -> x in @vowels end) do
          nil -> {word, r1, r2}
          _idx -> {String.slice(word, 0..-2), String.slice(r1, 0..-2), String.slice(r2, 0..-2)}
        end

      _ ->
        {word, r1, r2}
    end
  end

  def step1b({word, r1, r2}) do
    case first_suffix_match(word, @step1b_suffixes) do
      nil ->
        {word, r1, r2}

      suffix when suffix in ["eed", "eedly"] ->
        if String.ends_with?(r1, suffix) do
          word = String.replace_suffix(word, suffix, "ee")

          r1 =
            if String.length(r1) >= String.length(suffix),
              do: String.replace_suffix(r1, suffix, "ee"),
              else: ""

          r2 =
            if String.length(r2) >= String.length(suffix),
              do: String.replace_suffix(r2, suffix, "ee"),
              else: ""

          {word, r1, r2}
        else
          {word, r1, r2}
        end

      suffix ->
        idx = String.length(suffix) + 1

        case String.slice(word, 0..-idx)
             |> String.graphemes()
             |> Enum.find(fn x -> x in @vowels end) do
          nil ->
            {word, r1, r2}

          _vowel_found ->
            word = String.slice(word, 0..-idx)
            r1 = String.slice(r1, 0..-idx)
            r2 = String.slice(r2, 0..-idx)

            cond do
              first_suffix_match(word, ["at", "bl", "iz"]) ->
                word = word <> "e"
                r1 = r1 <> "e"
                r2 = if String.length(word) > 5 or String.length(r1) >= 3, do: r2 <> "e", else: r2

                {word, r1, r2}

              first_suffix_match(word, @double_consanants) ->
                word = String.slice(word, 0..-2)
                r1 = String.slice(r1, 0..-2)
                r2 = String.slice(r2, 0..-2)

                {word, r1, r2}

              has_short_syllable?(word, r1) ->
                word = word <> "e"
                r1 = if String.length(r1) > 0, do: r1 <> "e", else: r1
                r2 = if String.length(r2) > 0, do: r2 <> "e", else: r2

                {word, r1, r2}

              true ->
                {word, r1, r2}
            end
        end
    end
  end

  def step1c({word, r1, r2}) do
    case String.length(word) > 2 and String.ends_with?(word, ["y", "Y"]) and
           String.at(word, -2) not in @vowels do
      true ->
        word = String.slice(word, 0..-2) <> "i"
        r1 = if String.length(r1) >= 1, do: String.slice(r1, 0..-2) <> "i", else: ""
        r2 = if String.length(r2) >= 1, do: String.slice(r2, 0..-2) <> "i", else: ""

        {word, r1, r2}

      false ->
        {word, r1, r2}
    end
  end

  defp step2({word, r1, r2}) do
    suffix =
      case first_suffix_match(word, @step2_suffixes) do
        nil -> nil
        s -> if String.ends_with?(r1, s), do: s, else: nil
      end

    case suffix do
      "tional" ->
        word = String.slice(word, 0..-3)
        r1 = String.slice(r1, 0..-3)
        r2 = String.slice(r2, 0..-3)

        {word, r1, r2}

      suffix when suffix in ["enci", "anci", "abli"] ->
        word = String.slice(word, 0..-2) <> "e"
        r1 = if String.length(r1) >= 1, do: String.slice(r1, 0..-2) <> "e", else: ""
        r2 = if String.length(r2) >= 1, do: String.slice(r2, 0..-2) <> "e", else: ""

        {word, r1, r2}

      "entli" ->
        word = String.slice(word, 0..-3)
        r1 = String.slice(r1, 0..-3)
        r2 = String.slice(r2, 0..-3)

        {word, r1, r2}

      suffix when suffix in ["izer", "ization"] ->
        word = String.replace_suffix(word, suffix, "ize")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ize"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ize"),
            else: ""

        {word, r1, r2}

      suffix when suffix in ["ational", "ation", "ator"] ->
        word = String.replace_suffix(word, suffix, "ate")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ate"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ate"),
            else: "e"

        {word, r1, r2}

      suffix when suffix in ["alism", "aliti", "alli"] ->
        word = String.replace_suffix(word, suffix, "al")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "al"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "al"),
            else: ""

        {word, r1, r2}

      "fulness" ->
        word = String.slice(word, 0..-5)
        r1 = String.slice(r1, 0..-5)
        r2 = String.slice(r2, 0..-5)

        {word, r1, r2}

      suffix when suffix in ["ousli", "ousness"] ->
        word = String.replace_suffix(word, suffix, "ous")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ous"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ous"),
            else: ""

        {word, r1, r2}

      suffix when suffix in ["iveness", "iviti"] ->
        word = String.replace_suffix(word, suffix, "ive")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ive"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ive"),
            else: "e"

        {word, r1, r2}

      suffix when suffix in ["biliti", "bli"] ->
        word = String.replace_suffix(word, suffix, "ble")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ble"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ble"),
            else: ""

        {word, r1, r2}

      "ogi" ->
        if String.at(word, -4) == "l" do
          {String.slice(word, 0..-2), String.slice(r1, 0..-2), String.slice(r2, 0..-2)}
        else
          {word, r1, r2}
        end

      suffix when suffix in ["fulli", "lessli"] ->
        {String.replace_suffix(word, "li", ""), String.replace_suffix(r1, "li", ""),
         String.replace_suffix(r2, "li", "")}

      "li" ->
        if String.at(word, -3) in @valid_li_ending do
          {String.replace_suffix(word, "li", ""), String.replace_suffix(r1, "li", ""),
           String.replace_suffix(r2, "li", "")}
        else
          {word, r1, r2}
        end

      _ ->
        {word, r1, r2}
    end
  end

  def step3({word, r1, r2}) do
    suffix =
      case first_suffix_match(word, @step3_suffixes) do
        nil -> nil
        s -> if String.ends_with?(r1, s), do: s, else: nil
      end

    case suffix do
      "tional" ->
        {String.slice(word, 0..-3), String.slice(r1, 0..-3), String.slice(r2, 0..-3)}

      "ational" ->
        word = String.replace_suffix(word, suffix, "ate")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ate"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ate"),
            else: ""

        {word, r1, r2}

      "alize" ->
        {String.slice(word, 0..-4), String.slice(r1, 0..-4), String.slice(r2, 0..-4)}

      suffix when suffix in ["icate", "iciti", "ical"] ->
        word = String.replace_suffix(word, suffix, "ic")

        r1 =
          if String.length(r1) >= String.length(suffix),
            do: String.replace_suffix(r1, suffix, "ic"),
            else: ""

        r2 =
          if String.length(r2) >= String.length(suffix),
            do: String.replace_suffix(r2, suffix, "ic"),
            else: ""

        {word, r1, r2}

      suffix when suffix in ["ful", "ness"] ->
        idx = String.length(suffix) + 1
        {String.slice(word, 0..-idx), String.slice(r1, 0..-idx), String.slice(r2, 0..-idx)}

      "ative" ->
        if String.ends_with?(r2, "ative") do
          {String.slice(word, 0..-6), String.slice(r1, 0..-6), String.slice(r2, 0..-6)}
        else
          {word, r1, r2}
        end

      _ ->
        {word, r1, r2}
    end
  end

  defp step4({word, r1, r2}) do
    suffix =
      case first_suffix_match(word, @step4_suffixes) do
        nil -> nil
        s -> if String.ends_with?(r2, s), do: s, else: nil
      end

    case suffix do
      nil ->
        {word, r1, r2}

      "ion" ->
        if String.at(word, -4) in ["s", "t"] do
          {String.slice(word, 0..-4), String.slice(r1, 0..-4), String.slice(r2, 0..-4)}
        else
          {word, r1, r2}
        end

      _ ->
        idx = String.length(suffix) + 1
        {String.slice(word, 0..-idx), String.slice(r1, 0..-idx), String.slice(r2, 0..-idx)}
    end
  end

  defp step5({word, r1, r2}) do
    cond do
      String.ends_with?(r2, "l") and String.at(word, -2) == "l" ->
        {String.slice(word, 0..-2), r1, r2}

      String.ends_with?(r2, "e") ->
        {String.slice(word, 0..-2), r1, r2}

      String.ends_with?(r1, "e") and
        String.length(word) >= 4 and
          (String.at(word, -2) in @vowels or
             String.at(word, -2) in ["w", "x", "Y"] or
             String.at(word, -3) not in @vowels or
             String.at(word, -4) in @vowels) ->
        {String.slice(word, 0..-2), r1, r2}

      true ->
        {word, r1, r2}
    end
  end
end

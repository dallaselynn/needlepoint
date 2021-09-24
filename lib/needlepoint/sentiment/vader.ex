defmodule Needlepoint.Sentiment.Vader do
  @moduledoc """
  An imeplemntation of VADER rule based sentiment analysis, based on the NLTK port.

  Hutto, C.J. & Gilbert, E.E. (2014). VADER: A Parsimonious Rule-based Model for
  Sentiment Analysis of Social Media Text. Eighth International Conference on
  Weblogs and Social Media (ICWSM-14). Ann Arbor, MI, June 2014.
  """

  alias Needlepoint.Util

  @punc_regex ~r/[!"\#\$%&'\(\)\*\+,\-\.\/:;<=>\?@\[\]\^_`\{\|\}~\.]/

  @b_incr 0.293
  @b_decr -0.293

  # (empirically derived mean sentiment intensity rating increase for using ALLCAPs to emphasize a word)
  @c_incr 0.733
  @n_scalar -0.74

  @negate ~w(aint arent cannot cant couldnt darent didnt doesnt ain't aren't can't couldn't daren't
    didn't doesn'tdont hadnt hasnt havent isnt mightnt mustnt neither don't hadn't hasn't haven't
    isn't mightn't mustn't neednt needn't never none nope nor not nothing nowhere oughtnt shant
    shouldnt uhuh wasnt werent oughtn't shan't shouldn't uh-uh wasn't weren't without wont wouldnt
    won't wouldn't rarely seldom despite)

  @booster %{
    "absolutely" => @b_incr,
    "amazingly" => @b_incr,
    "awfully" => @b_incr,
    "completely" => @b_incr,
    "considerable" => @b_incr,
    "considerably" => @b_incr,
    "decidedly" => @b_incr,
    "deeply" => @b_incr,
    "effing" => @b_incr,
    "enormous" => @b_incr,
    "enormously" => @b_incr,
    "entirely" => @b_incr,
    "especially" => @b_incr,
    "exceptional" => @b_incr,
    "exceptionally" => @b_incr,
    "extreme" => @b_incr,
    "extremely" => @b_incr,
    "fabulously" => @b_incr,
    "flipping" => @b_incr,
    "flippin" => @b_incr,
    "frackin" => @b_incr,
    "fracking" => @b_incr,
    "fricking" => @b_incr,
    "frickin" => @b_incr,
    "frigging" => @b_incr,
    "friggin" => @b_incr,
    "fully" => @b_incr,
    "fuckin" => @b_incr,
    "fucking" => @b_incr,
    "fuggin" => @b_incr,
    "fugging" => @b_incr,
    "greatly" => @b_incr,
    "hella" => @b_incr,
    "highly" => @b_incr,
    "hugely" => @b_incr,
    "incredible" => @b_incr,
    "incredibly" => @b_incr,
    "intensely" => @b_incr,
    "major" => @b_incr,
    "majorly" => @b_incr,
    "more" => @b_incr,
    "most" => @b_incr,
    "particularly" => @b_incr,
    "purely" => @b_incr,
    "quite" => @b_incr,
    "really" => @b_incr,
    "remarkably" => @b_incr,
    "so" => @b_incr,
    "substantially" => @b_incr,
    "thoroughly" => @b_incr,
    "total" => @b_incr,
    "totally" => @b_incr,
    "tremendous" => @b_incr,
    "tremendously" => @b_incr,
    "uber" => @b_incr,
    "unbelievably" => @b_incr,
    "unusually" => @b_incr,
    "utter" => @b_incr,
    "utterly" => @b_incr,
    "very" => @b_incr,
    "almost" => @b_decr,
    "barely" => @b_decr,
    "hardly" => @b_decr,
    "just enough" => @b_decr,
    "kind of" => @b_decr,
    "kinda" => @b_decr,
    "kindof" => @b_decr,
    "kind-of" => @b_decr,
    "less" => @b_decr,
    "little" => @b_decr,
    "marginal" => @b_decr,
    "marginally" => @b_decr,
    "occasional" => @b_decr,
    "occasionally" => @b_decr,
    "partly" => @b_decr,
    "scarce" => @b_decr,
    "scarcely" => @b_decr,
    "slight" => @b_decr,
    "slightly" => @b_decr,
    "somewhat" => @b_decr,
    "sort of" => @b_decr,
    "sorta" => @b_decr,
    "sortof" => @b_decr,
    "sort-of" => @b_decr
  }

  # check for special case idioms and phrases containing lexicon words
  @special_cases %{
    "the shit" => 3,
    "the bomb" => 3,
    "cut the mustard" => 2,
    "bad ass" => 1.5,
    "badass" => 1.5,
    "bus stop" => 0.0,
    "yeah right" => -2,
    "kiss of death" => -1.5,
    "hand to mouth" => -2,
    "broken heart" => -2.9,
    "to die for" => 3,
    "beating heart" => 3.1
  }

  @punc_list ~w(. ! ? , ; : - ' " !! !!! ?? ??? ?!? !?! ?!?! !?!?)

  ### function from the Constants class in the nltk version.

  # determine if "least" occurs not preceded by "at"
  def has_least_pair(words) do
    List.zip([words, tl(words)])
    |> Enum.find_value(false, fn {first, second} ->
      String.downcase(first) != "at" and String.downcase(second) == "least"
    end)
  end

  # determine if input contains negated words, return true or false
  def negated(words, include_nt \\ true) do
    has_neg_word = Enum.find_value(words, fn x ->
      (String.downcase(x) in @negate) or
      (include_nt and String.contains?(x, "n't"))
    end)

    case has_neg_word do
      true -> true
      _ -> has_least_pair(words)
    end
  end

  # Normalize the score to be between -1 and 1 using an alpha that approximates the max expected value
  def normalize(score, alpha \\ 15), do: score / :math.sqrt((score * score) + alpha)

  # Check if the preceding words increase, decrease, or negate/nullify the valence
  # make sure to lower case the word.
  def scalar_inc_dec(word, valence, is_cap_diff?) do
    case Map.get(@booster, String.downcase(word)) do
      nil -> 0.0
      scalar ->
        scalar = if valence < 0, do: -scalar, else: scalar
        cond do
          Util.is_upcase?(word) and is_cap_diff? and valence > 0 ->
            scalar + @c_incr
          Util.is_upcase?(word) and is_cap_diff? and valence < 0 ->
            scalar - @c_incr
          true ->
            scalar
        end
    end
  end

  ### end Constant functions.

  ### functions defiend in SentiText in the nltk version.

  # take text and return map like %{"cat," => "cat"} - where there is an key for
  # every word in the text greater than one character with leading and trailing
  # punctuation from @punc_list added.  so a 3 word text will have a size of 102.
  def words_plus_punc(text) do
    words =
      Regex.replace(@punc_regex, text, "")
      |> String.split()
      |> Enum.filter(fn x -> String.length(x) > 1 end)

    acc = Map.new()

    Util.product(@punc_list, words) |>
      Enum.reduce(acc, fn x, map -> Map.put(map, List.to_string(x), tl(x)) end)

    Util.product(words, @punc_list) |>
      Enum.reduce(acc, fn x, map -> Map.put(map, List.to_string(x), hd(x)) end)
  end

  # swap out punctated words with their words_plus_punc versions.
  def words_and_emoticons(text) do
    words_punc_map = words_plus_punc(text)

    String.split(text)
    |> Enum.reject(&String.length(&1) < 2)
    |> Enum.map(&Map.get(words_punc_map, &1, &1))
  end

  # TODO: this should probably be called like 'has_allcap_differential?' or something
  # Check whether some words in the input are ALL CAPS but not all of them
  def allcap_differential(words) do
    Enum.any?(words, &Util.is_upcase?(&1)) and Enum.any?(words, fn x -> not Util.is_upcase?(x) end)
  end

  ## END SentiText functions.

  ## Functions from SentimentIntensityAnalyzer

  # convert lexicon file to a map of %{word => measure}
  def load_lexicon() do
    Path.join(:code.priv_dir(:needlepoint), "vader_lexicon.txt") |>
    File.stream!
    |> Stream.map(fn x -> String.split(x, "\t", trim: true) |> Enum.take(2) end)
    |> Enum.into(%{}, fn x -> {hd(x), String.to_float(List.last(x))} end)
  end

  # returns a map like %{"neg" => 0.0, "neu" => 1.0, "pos" => 0.0, "compound" => 0.0}
  def polarity_scores(text) do
    words = words_and_emoticons(text)
    lexicon = load_lexicon()

    Enum.map(0..length(words)-1, &valence(lexicon, words, &1))
    |> IO.inspect(label: "valences")
    |> but_check(words)
    |> IO.inspect(label: "after but check")
    |> score_valence(text)
  end

  # compute the final scores and return a map with keys neg, neu, pos and compound
  def score_valence(valences, _text) when length(valences) == 0 do
    %{neg: 0.0, neu: 0.0, pos: 0.0, compound: 0.0}
  end

  def score_valence(valences, text) do

    valence_sum = Enum.sum(valences)
    punct_emph_amplifier = punctuation_emphasis_adjustment(text)
    sum_s = if valence_sum > 0, do: valence_sum + punct_emph_amplifier, else: valence_sum - punct_emph_amplifier
    compound = normalize(sum_s)

    # discriminate between positive, negative and neutral sentiment scores
    sifted = sift_sentiment_scores(valences)

    if sifted.pos_sum > abs(sifted.neg_sum), do: Map.update!(sifted, :pos_sum, &(&1 + punct_emph_amplifier))
    if sifted.pos_sum < abs(sifted.neg_sum), do: Map.update!(sifted, :pos_sum, &(&1 - punct_emph_amplifier))

    total = Enum.sum([sifted.pos_sum, abs(sifted.neg_sum), sifted.neu_count])

    %{
      compound: compound,
      pos: abs(sifted.pos_sum / total),
      neg: abs(sifted.neg_sum / total),
      neu: abs(sifted.neu_count / total),
    }
  end

  # take all the sentiments and return a map of the sum of the positives+1,
  # the sum of the negatives-1, and the count of the neutrals
  def sift_sentiment_scores(valences) do
    Enum.reduce(
      valences,
      %{pos_sum: 0.0, neg_sum: 0.0, neu_count: 0},
      fn x, acc ->
        cond do
          x < 0 -> Map.update(acc, :neg_sum, 0, fn ev -> ev + (x - 1) end)
          x > 0 -> Map.update(acc, :pos_sum, 0, fn ev -> ev + (x + 1) end)
          x == 0 -> Map.update(acc, :neu_count, 0, fn ev -> ev + 1 end)
        end
    end)
  end

  # add emphasis from exclamation points and question marks and return the new sum
  def punctuation_emphasis_adjustment(text) do
    # check for added emphasis resulting from exclamation points (up to 4 of them)
    ep_amplifier = Enum.count_until(String.graphemes(text), fn x -> x == "!" end, 4) * 0.292
    # now check for question mark adjustment
    qm_count = Enum.count(String.graphemes(text), fn x -> x == "?" end)
    qm_amplifier =
      cond do
        qm_count > 3 -> 0.96
        qm_count > 1 -> qm_count * 0.18
        true -> 0
      end

    ep_amplifier + qm_amplifier
  end

  # get the valence of the word in words at position idx
  def valence(lexicon, words, idx) do
    case is_valence_zero?(lexicon, words, idx) do
      true -> 0
      _ -> calculate_valence(lexicon, words, idx)
    end
  end

  # get the valence for word at position idx that isn't a special zero case.
  def calculate_valence(lexicon, words, idx) do
    # if it's not here it should be 0 already.
    word = String.downcase(Enum.at(words, idx))
    initial_valence = Map.fetch!(lexicon, word)
    has_caps_differential? = allcap_differential(words)

    initial_valence
    |> adjust_valence_for_caps(Util.is_upcase?(word), has_caps_differential?)
    |> adjust_valence_for_previous_words(lexicon, words, idx, has_caps_differential?)
    |> adjust_valence_for_least(lexicon, words, idx)
  end

  # adjust valence for preceding "least" phrases and return the new valence.
  def adjust_valence_for_least(valence, lexicon, words, idx) do
    word1 = String.downcase(Enum.at(words, idx-1))
    word2 = String.downcase(Enum.at(words, idx-2))
    word1_not_in_lexicon? = not Map.has_key?(lexicon, word1)
    word1_is_least? = word1 == "least"
    word2_is_not_at_or_very? = word2 not in ["at", "very"]

    cond do
      word1_not_in_lexicon? and word1_is_least? and idx > 1 and word2_is_not_at_or_very? ->
        valence * @n_scalar
      word1_not_in_lexicon? and word1_is_least? ->
        valence * @n_scalar
      true ->
        valence
    end
  end

  # adjust valence for capitalization - and return the new valence.
  def adjust_valence_for_caps(valence, is_upcase?, has_caps_differential?)
  def adjust_valence_for_caps(valence, true, true) do
    if valence > 0, do: valence + @c_incr, else: valence - @c_incr
  end
  def adjust_valence_for_caps(valence, _, _), do: valence

  # change valence based on surrounding words and return the new valence - skip the first three words.
  def adjust_valence_for_previous_words(valence, lexicon, words, idx, has_caps_differential?) do
    Enum.reduce(0..2, valence, fn start_i, acc ->
      has_previous_words? = idx > start_i
      prev_word = Enum.at(words, idx-(start_i+1))
      previous_in_lexicon? = Map.has_key?(lexicon, String.downcase(prev_word))

      if has_previous_words? and not previous_in_lexicon? do
        s = scalar_inc_dec(prev_word, acc, has_caps_differential?)
        inc_dec_adjustment =
          cond do
            start_i == 1 and s != 0 ->
              0.95
            start_i == 2 and s != 0 ->
              0.9
            true ->
              1
          end

        updated_valence = (acc + (s * inc_dec_adjustment)) * never_check_adjustment(words, start_i, idx)
        idioms_check_adjustment(updated_valence, start_i, words, idx)
      else
        valence
      end
    end)
  end

  def but_check(valences, words) do
    case Enum.find_index(words, fn x -> String.downcase(x) == "but" end) do
      nil -> valences
      but_idx -> Enum.map(Enum.with_index(valences),
        fn {elem,idx} ->
          cond do
            idx < but_idx ->
              elem * 0.5
            idx > but_idx ->
              elem * 1.5
            true ->
              elem
          end
        end)
    end
  end

  # adjust valence for some known idioms
  def idioms_check_adjustment(valence, start_i, words, idx)
  def idioms_check_adjustment(valence, start_i, _words, _idx) when start_i != 2, do: valence
  def idioms_check_adjustment(valence, start_i, words, idx) when start_i == 2 do
    onezero = Enum.join([Enum.at(words, idx-1), Enum.at(words, idx)], " ")
    twoonezero = Enum.join([Enum.at(words, idx-2), Enum.at(words, idx-1), Enum.at(words, idx)], " ")
    twoone = Enum.join([Enum.at(words, idx-2), Enum.at(words, idx-1)], " ")
    threetwoone = Enum.join([Enum.at(words, idx-3), Enum.at(words, idx-2), Enum.at(words, idx-1)], " ")
    threetwo = Enum.join([Enum.at(words, idx-3), Enum.at(words, idx-2)], " ")
    zeroone = "#{Enum.at(words,idx)} #{Enum.at(words,idx + 1)}"
    zeroonetwo = "#{Enum.at(words,idx)} #{Enum.at(words,idx + 1)} #{Enum.at(words,idx + 2)}"

    sequences = [onezero, twoonezero, twoone, threetwoone, threetwo, zeroone, zeroonetwo]

    bigram_adjustment =
      cond do
        Map.has_key?(@booster, threetwo) or Map.has_key?(@booster, twoone) ->
          @b_decr
        true ->
          0
      end

    Enum.find_value(sequences, valence, &Map.get(@special_cases, &1)) + bigram_adjustment
  end

  # return the valence multiplier based on various "never" phrasings.
  def never_check_adjustment(words, start_i, idx)
  def never_check_adjustment(words, 0, idx) do
    if negated([Enum.at(words, idx-1)]), do: @n_scalar, else: 1.0
  end
  def never_check_adjustment(words, 1, idx) do
    cond do
      Enum.at(words, idx-2) == "never" and Enum.at(words, idx-1) in ["so", "this"] ->
        1.5
      negated([Enum.at(words, idx-2)]) ->
        @n_scalar
      true ->
        1.0
    end
  end
  def never_check_adjustment(words, 2, idx) do
    cond do
      (Enum.at(words, idx-3) == "never" and Enum.at(words,idx-2) in ["so", "this"]) or Enum.at(words,idx-1) in ["so","this"] ->
        1.25
      negated([Enum.at(words,idx-3)]) ->
        @n_scalar
      true ->
        1.0
    end
  end
  def never_check_adjustment(_words, _start_i, _idx), do: 1.0

  # valence should be zero for the word at idx in the list of words if
  # it is "kind" and the next word is "of" or if it is in the booster dict
  # or if it is not in the lexicon.
  def is_valence_zero?(lexicon, words, idx) do
    word = String.downcase(Enum.at(words, idx))
    next_word = String.downcase(Enum.at(words, idx+1, ""))

    Map.has_key?(@booster, word) or (word == "kind" and next_word == "of") or (not Map.has_key?(lexicon, word))
  end
end

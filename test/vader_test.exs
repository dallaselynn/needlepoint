defmodule SentimentVaderTest do
  use ExUnit.Case

  alias Needlepoint.Sentiment.Vader

  @sentences %{
    "VADER is smart, handsome, and funny." => %{compound: 0.8316, neg: 0.0, neu: 0.254, pos: 0.746},
    "VADER is smart, handsome, and funny!" => %{compound: 0.8439, neg: 0.0, neu: 0.248, pos: 0.752},
    "VADER is very smart, handsome, and funny." => %{compound: 0.8545, neg: 0.0, neu: 0.299, pos: 0.701},
    "VADER is VERY SMART, handsome, and FUNNY." => %{compound: 0.9227, neg: 0.0, neu: 0.246, pos: 0.754},
    "VADER is VERY SMART, handsome, and FUNNY!!!" => %{compound: 0.9342, neg: 0.0, neu: 0.233, pos: 0.767},
    "VADER is VERY SMART, really handsome, and INCREDIBLY FUNNY!!!" => %{compound: 0.9469, neg: 0.0, neu: 0.294, pos: 0.706},
    "The book was good." => %{compound: 0.4404, neg: 0.0, neu: 0.508, pos: 0.492},
    "The book was kind of good." => %{compound: 0.3832, neg: 0.0, neu: 0.657, pos: 0.343},
    "The plot was good, but the characters are uncompelling and the dialog is not great." => %{compound: -0.7042, neg: 0.327, neu: 0.579, pos: 0.094},
    "A really bad, horrible book." => %{compound: -0.8211, neg: 0.791, neu: 0.209, pos: 0.0},
    "At least it isn't a horrible book." => %{compound: 0.431, neg: 0.0, neu: 0.637, pos: 0.363},
    ":) and :D" => %{compound: 0.7925, neg: 0.0, neu: 0.124, pos: 0.876},
    "" => %{compound: 0.0, neg: 0.0, neu: 0.0, pos: 0.0},
    "Today sux" => %{compound: -0.3612, neg: 0.714, neu: 0.286, pos: 0.0},
    "Today sux!" => %{compound: -0.4199, neg: 0.736, neu: 0.264, pos: 0.0},
    "Today SUX!" => %{compound: -0.5461, neg: 0.779, neu: 0.221, pos: 0.0},
    "Today kinda sux! But I'll get by, lol" => %{compound: 0.5249, neg: 0.138, neu: 0.517, pos: 0.344},
    "It was one of the worst movies I've seen, despite good reviews." => %{compound: -0.7584, neg: 0.394, neu: 0.606, pos: 0.0},
    "Unbelievably bad acting!!" => %{compound: -0.6572, neg: 0.686, neu: 0.314, pos: 0.0},
    "Poor direction." => %{compound: -0.4767, neg: 0.756, neu: 0.244, pos: 0.0},
    "VERY poor production." => %{compound: -0.6281, neg: 0.674, neu: 0.326, pos: 0.0},
    "The movie was bad." => %{compound: -0.5423, neg: 0.538, neu: 0.462, pos: 0.0},
    "Very bad movie." => %{compound: -0.5849, neg: 0.655, neu: 0.345, pos: 0.0},
    "VERY bad movie." => %{compound: -0.6732, neg: 0.694, neu: 0.306, pos: 0.0},
    "VERY BAD movie." => %{compound: -0.7398, neg: 0.724, neu: 0.276, pos: 0.0},
    "VERY BAD movie!" => %{compound: -0.7616, neg: 0.735, neu: 0.265, pos: 0.0}
  }

  @trickysentences %{
    "Most automated sentiment analysis tools are shit." => %{compound: -0.5574, neg: 0.375, neu: 0.625, pos: 0.0},
    "VADER sentiment analysis is the shit." => %{compound: 0.6124, neg: 0.0, neu: 0.556, pos: 0.444},
    "Sentiment analysis has never been good." => %{compound: -0.3412, neg: 0.325, neu: 0.675, pos: 0.0},
    "Sentiment analysis with VADER has never been this good." => %{compound: 0.5228, neg: 0.0, neu: 0.703, pos: 0.297},
    "Warren Beatty has never been so entertaining." => %{compound: 0.5777, neg: 0.0, neu: 0.616, pos: 0.384},
    "I won't say that the movie is astounding and I wouldn't claim that the movie is too banal either." => %{compound: 0.4215, neg: 0.0, neu: 0.851, pos: 0.149},
    "I like to hate Michael Bay films, but I couldn't fault this one" => %{compound: 0.3153, neg: 0.157, neu: 0.534, pos: 0.309},
    "It's one thing to watch an Uwe Boll film, but another thing entirely to pay for it" => %{compound: -0.2541, neg: 0.112, neu: 0.888, pos: 0.0},
    "The movie was too good" => %{compound: 0.4404, neg: 0.0, neu: 0.58, pos: 0.42},
    "This movie was actually neither that funny, nor super witty." => %{compound: -0.6759, neg: 0.41, neu: 0.59, pos: 0.0},
    "This movie doesn't care about cleverness, wit or any other kind of intelligent humor." => %{compound: -0.1338, neg: 0.265, neu: 0.497, pos: 0.239},
    "Those who find ugly meanings in beautiful things are corrupt without being charming." => %{compound: -0.3553, neg: 0.314, neu: 0.493, pos: 0.192},
    "There are slow and repetitive parts, BUT it has just enough spice to keep it interesting." => %{compound: 0.4678, neg: 0.079, neu: 0.735, pos: 0.186},
    "The script is not fantastic, but the acting is decent and the cinematography is EXCELLENT!" => %{compound: 0.7565, neg: 0.092, neu: 0.607, pos: 0.301},
    "Roger Dodger is one of the most compelling variations on this theme." => %{compound: 0.2944, neg: 0.0, neu: 0.834, pos: 0.166},
    "Roger Dodger is one of the least compelling variations on this theme." => %{compound: -0.1695, neg: 0.132, neu: 0.868, pos: 0.0},
    "Roger Dodger is at least compelling as a variation on the theme." => %{compound: 0.2263, neg: 0.0, neu: 0.84, pos: 0.16},
    "they fall in love with the product" => %{compound: 0.6369, neg: 0.0, neu: 0.588, pos: 0.412},
    "but then it breaks" => %{compound: 0.0, neg: 0.0, neu: 1.0, pos: 0.0},
    "usually around the time the 90 day warranty expires" => %{compound: 0.0, neg: 0.0, neu: 1.0, pos: 0.0},
    "the twin towers collapsed today" => %{compound: -0.2732, neg: 0.344, neu: 0.656, pos: 0.0},
    "However, Mr. Carter solemnly argues, his client carried out the kidnapping under orders and in the 'least offensive way possible.'" => %{compound: -0.5859, neg: 0.23, neu: 0.697, pos: 0.074}
  }

  test "sentences" do
    for {sentence, scores} <- @sentences do
      assert Vader.polarity_scores(sentence) == scores
    end
  end

  test "tricky sentences" do
    for {sentence, scores} <- @trickysentences do
      assert Vader.polarity_scores(sentence) == scores
    end
  end
end

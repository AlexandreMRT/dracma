# frozen_string_literal: true

require "test_helper"

class SentimentAnalyzerTest < ActiveSupport::TestCase
  test "positive text scores positive" do
    score = SentimentAnalyzer.score("great profit earnings growth excellent")

    assert_operator score, :>, 0
  end

  test "negative text scores negative" do
    score = SentimentAnalyzer.score("loss crisis debt decline bankruptcy")

    assert_operator score, :<, 0
  end

  test "neutral text scores near zero" do
    score = SentimentAnalyzer.score("The company released a statement today.")

    assert_in_delta 0.0, score, 0.3
  end

  test "score is bounded between -1 and 1" do
    score = SentimentAnalyzer.score("great amazing excellent wonderful outstanding profit")

    assert_operator score, :<=, 1.0
    assert_operator score, :>=, -1.0
  end

  test "label returns correct labels" do
    assert_equal "positive", SentimentAnalyzer.label(0.3)
    assert_equal "negative", SentimentAnalyzer.label(-0.3)
    assert_equal "neutral", SentimentAnalyzer.label(0.0)
  end

  test "analyze returns average and headline" do
    avg, headline = SentimentAnalyzer.analyze([ "Great profit", "Terrible loss" ])

    assert_kind_of Float, avg
    assert_kind_of String, headline
  end

  test "analyze empty returns nil" do
    avg, headline = SentimentAnalyzer.analyze([])

    assert_nil avg
    assert_nil headline
  end

  test "portuguese positive words" do
    score = SentimentAnalyzer.score("lucro alta crescimento superou recorde")

    assert_operator score, :>, 0
  end

  test "portuguese negative words" do
    score = SentimentAnalyzer.score("prejuízo queda crise endividamento falência")

    assert_operator score, :<, 0
  end
end

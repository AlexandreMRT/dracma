# frozen_string_literal: true

require "test_helper"

class NewsFetcherTest < ActiveSupport::TestCase
  test "english parses google rss items and applies max" do
    stub_request(:get, %r{\Ahttps://news\.google\.com/rss/search\?.*\z})
      .to_return(status: 200, body: rss_payload, headers: { "Content-Type" => "application/rss+xml" })

    items = NewsFetcher.english("AAPL", max: 1)

    assert_equal 1, items.size
    assert_equal "Apple jumps after earnings", items.first[:title]
    assert_equal "Apple jumps after earnings. Shares gained in late trading", items.first[:text]
    assert_equal "Reuters", items.first[:source]
  end

  test "portuguese strips .SA suffix from ticker in query" do
    query = nil

    stub_request(:get, %r{\Ahttps://news\.google\.com/rss/search\?.*\z}).with do |request|
      query = URI.decode_www_form(request.uri.query).to_h["q"]
      true
    end.to_return(status: 200, body: rss_payload, headers: { "Content-Type" => "application/rss+xml" })

    NewsFetcher.portuguese("Petrobras", "PETR4.SA", max: 1)

    assert_includes query, "Petrobras"
    assert_includes query, "PETR4"
    refute_includes query, "PETR4.SA"
  end

  test "sentiment combines pt and en with weighted average for brazilian assets" do
    english_news = [ { title: "EN Headline", text: "text" } ]
    portuguese_news = [ { title: "PT Headline", text: "text" } ]

    analyzer = lambda do |_items, lang:|
      lang == :pt ? [ 0.8, "Headline PT" ] : [ 0.2, "Headline EN" ]
    end

    with_singleton_stub(NewsFetcher, :english, ->(_ticker, max: 10) { english_news }) do
      with_singleton_stub(NewsFetcher, :portuguese, ->(_company, _ticker, max: 10) { portuguese_news }) do
        with_singleton_stub(SentimentAnalyzer, :analyze, analyzer) do
          result = NewsFetcher.sentiment("PETR4.SA", "Petrobras", brazilian: true)

          assert_equal 1, result[:news_count_pt]
          assert_equal 1, result[:news_count_en]
          assert_equal "Headline PT", result[:news_headline_pt]
          assert_equal "Headline EN", result[:news_headline_en]
          assert_in_delta 0.8, result[:news_sentiment_pt], 0.001
          assert_in_delta 0.2, result[:news_sentiment_en], 0.001
          assert_in_delta 0.56, result[:news_sentiment_combined], 0.001
          assert_equal "positive", result[:news_sentiment_label]
        end
      end
    end
  end

  test "sentiment skips portuguese feed for non brazilian assets" do
    english_news = [ { title: "EN Headline", text: "text" } ]

    with_singleton_stub(NewsFetcher, :english, ->(_ticker, max: 10) { english_news }) do
      with_singleton_stub(NewsFetcher, :portuguese, ->(_company, _ticker, max: 10) { [ { title: "PT Headline", text: "text" } ] }) do
        with_singleton_stub(SentimentAnalyzer, :analyze, ->(_items, lang:) { [ 0.3, "#{lang} headline" ] }) do
          result = NewsFetcher.sentiment("AAPL", "Apple", brazilian: false)

          assert_equal 0, result[:news_count_pt]
          assert_equal 1, result[:news_count_en]
          assert_nil result[:news_sentiment_pt]
          assert_in_delta 0.3, result[:news_sentiment_en], 0.001
          assert_in_delta 0.3, result[:news_sentiment_combined], 0.001
          assert_equal "positive", result[:news_sentiment_label]
        end
      end
    end
  end

  private

  def with_singleton_stub(object, method_name, implementation)
    original_method = object.method(method_name)
    object.define_singleton_method(method_name, implementation)
    yield
  ensure
    object.define_singleton_method(method_name, original_method)
  end

  def rss_payload
    <<~XML
      <rss version="2.0">
        <channel>
          <item>
            <title>Apple jumps after earnings</title>
            <description>Shares gained in late trading</description>
            <source>Reuters</source>
          </item>
          <item>
            <title>Second headline</title>
            <description></description>
            <source>Bloomberg</source>
          </item>
        </channel>
      </rss>
    XML
  end
end

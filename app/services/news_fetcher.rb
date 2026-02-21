# frozen_string_literal: true
# typed: true

require "net/http"
require "uri"
require "json"

# Google News RSS feed fetcher using Net::HTTP + Nokogiri (bundled with Rails).
# Replaces Python's feedparser.
class NewsFetcher
  extend T::Sig

  GOOGLE_NEWS_RSS = "https://news.google.com/rss/search"

  # Fetch English news via Yahoo Finance API.
  sig { params(ticker: String, max: Integer).returns(T::Array[T::Hash[Symbol, String]]) }
  def self.english(ticker, max: 10)
    uri = URI("https://query1.finance.yahoo.com/v8/finance/chart/#{ERB::Util.url_encode(ticker)}")
    # Yahoo Finance doesn't have a great free news endpoint;
    # fall back to Google News RSS in English
    fetch_google_news("#{ticker} stock", lang: "en", max: max)
  rescue StandardError => e
    Rails.logger.warn("NewsFetcher EN error for #{ticker}: #{e.message}")
    []
  end

  # Fetch Portuguese news via Google News RSS.
  sig { params(company_name: String, ticker: String, max: Integer).returns(T::Array[T::Hash[Symbol, String]]) }
  def self.portuguese(company_name, ticker, max: 10)
    clean_ticker = ticker.delete_suffix(".SA")
    query = "#{company_name} OR #{clean_ticker} ações bolsa"
    fetch_google_news(query, lang: "pt-BR", max: max)
  rescue StandardError => e
    Rails.logger.warn("NewsFetcher PT error for #{company_name}: #{e.message}")
    []
  end

  # Fetch and analyze news sentiment for a stock.
  sig { params(ticker: String, company_name: String, brazilian: T::Boolean).returns(T::Hash[Symbol, T.untyped]) }
  def self.sentiment(ticker, company_name, brazilian: true)
    result = T.let({
      news_sentiment_pt: nil, news_sentiment_en: nil, news_sentiment_combined: nil,
      news_count_pt: 0, news_count_en: 0,
      news_headline_pt: nil, news_headline_en: nil,
      news_sentiment_label: nil
    }, T::Hash[Symbol, T.untyped])

    # English news
    en_news = english(ticker)
    if en_news.any?
      result[:news_count_en] = en_news.size
      score, headline = SentimentAnalyzer.analyze(en_news, lang: :en)
      result[:news_sentiment_en] = score if score
      result[:news_headline_en] = headline&.slice(0, 500)
    end

    # Portuguese news (for Brazilian stocks)
    if brazilian
      pt_news = portuguese(company_name, ticker)
      if pt_news.any?
        result[:news_count_pt] = pt_news.size
        score, headline = SentimentAnalyzer.analyze(pt_news, lang: :pt)
        result[:news_sentiment_pt] = score if score
        result[:news_headline_pt] = headline&.slice(0, 500)
      end
    end

    # Combined score
    pt = result[:news_sentiment_pt]
    en = result[:news_sentiment_en]
    combined = if pt && en
                 (pt * 0.6) + (en * 0.4)
    else
                 pt || en
    end

    result[:news_sentiment_combined] = combined
    result[:news_sentiment_label] = SentimentAnalyzer.label(combined)
    result
  end

  # -------------------------------------------------------------------
  private_class_method
  # -------------------------------------------------------------------

  def self.fetch_google_news(query, lang: "en", max: 10)
    encoded = URI.encode_www_form_component(query)
    hl = lang == "pt-BR" ? "pt-BR" : "en"
    gl = lang == "pt-BR" ? "BR" : "US"
    ceid = lang == "pt-BR" ? "BR:pt-419" : "US:en"

    url = "#{GOOGLE_NEWS_RSS}?q=#{encoded}&hl=#{hl}&gl=#{gl}&ceid=#{ceid}"
    uri = URI(url)

    response = Net::HTTP.get_response(uri)
    return [] unless response.is_a?(Net::HTTPSuccess)

    doc = Nokogiri::XML(response.body)
    items = doc.xpath("//item")[0...max]

    items.map do |item|
      title = item.at_xpath("title")&.text || ""
      description = item.at_xpath("description")&.text || ""
      text = description.empty? ? title : "#{title}. #{description}"
      { title: title, text: text, source: item.at_xpath("source")&.text || "Google News" }
    end
  rescue StandardError => e
    Rails.logger.warn("Google News RSS error: #{e.message}")
    []
  end
end

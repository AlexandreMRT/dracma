# frozen_string_literal: true

module QuoteTasks
  module_function

  def format_percentage(value)
    return "n/a" if value.nil?

    format("%+.2f%%", value)
  end

  def print_list(label, items)
    return if items.empty?

    puts "#{label} (#{items.size}): #{items.join(', ')}"
  end

  def print_news_section(label, items)
    return if items.empty?

    puts "#{label}:"
    items.each do |item|
      puts "  - #{item[:ticker]} | #{format("%+.3f", item[:sentiment_score].to_f)} | #{item[:headline]}"
    end
  end
end

namespace :quotes do
  desc "Fetch all quotes once"
  task fetch: :environment do
    saved, errors = QuoteFetcher.new.fetch_all
    puts "Fetched #{saved} assets with #{errors} errors"
  end

  desc "Display active trading signals"
  task signals: :environment do
    summary = ApiDataService.signals_summary

    puts "Trading signals"
    QuoteTasks.print_list("Bullish", summary[:bullish].first(15))
    QuoteTasks.print_list("Bearish", summary[:bearish].first(15))

    unless summary[:rsi_oversold].empty?
      puts "RSI oversold:"
      summary[:rsi_oversold].first(10).each do |item|
        puts "  - #{item[:ticker]} (RSI #{item[:rsi]})"
      end
    end

    unless summary[:rsi_overbought].empty?
      puts "RSI overbought:"
      summary[:rsi_overbought].first(10).each do |item|
        puts "  - #{item[:ticker]} (RSI #{item[:rsi]})"
      end
    end

    QuoteTasks.print_list("Near 52W low", summary[:near_52w_low].first(10))
    QuoteTasks.print_list("Near 52W high", summary[:near_52w_high].first(10))
    QuoteTasks.print_list("Volume spike", summary[:volume_spike].first(10))
  end

  desc "Display news sentiment analysis"
  task news: :environment do
    positive = ApiDataService.news_items(sentiment: "positive", limit: 10)
    negative = ApiDataService.news_items(sentiment: "negative", limit: 10)

    if positive.empty? && negative.empty?
      puts "No news sentiment data available"
    else
      QuoteTasks.print_news_section("Positive news", positive)
      QuoteTasks.print_news_section("Negative news", negative)
    end
  end

  desc "Display Polymarket sentiment"
  task polymarket: :environment do
    sentiments = PolymarketClient.fetch_sentiment

    if sentiments.empty?
      puts "No Polymarket sentiment available"
      next
    end

    sentiments.sort_by { |_ticker, markets| -(PolymarketClient.aggregate(markets)[:total_volume].to_f) }
              .first(10)
              .each do |ticker, markets|
      aggregate = PolymarketClient.aggregate(markets)
      puts [
        ticker,
        aggregate[:label] || "n/a",
        "score=#{aggregate[:score] || 'n/a'}",
        "confidence=#{aggregate[:confidence] || 'n/a'}",
        "markets=#{aggregate[:market_count]}",
        "volume=#{aggregate[:total_volume].to_f.round(2)}"
      ].join(" | ")
    end
  end

  desc "Display market summary"
  task summary: :environment do
    data = ExporterService.report_data

    unless data
      puts "No quote data available"
      next
    end

    puts "Dracma summary @ #{data[:generated_at].strftime("%Y-%m-%d %H:%M")}"
    puts "Assets: #{data[:total_assets]}"
    puts "IBOV YTD: #{QuoteTasks.format_percentage(data.dig(:market_context, :ibov_ytd))}"
    puts "S&P 500 YTD: #{QuoteTasks.format_percentage(data.dig(:market_context, :sp500_ytd))}"
    puts "USD/BRL: #{data.dig(:market_context, :usd_brl) || 'n/a'}"
    puts

    puts "Top gainers:"
    data.dig(:top_movers, :gainers).first(5).each do |row|
      puts "  - #{row[:ticker]} #{QuoteTasks.format_percentage(row[:var_1d])}"
    end

    puts "Top losers:"
    data.dig(:top_movers, :losers).first(5).each do |row|
      puts "  - #{row[:ticker]} #{QuoteTasks.format_percentage(row[:var_1d])}"
    end

    puts "Bullish count: #{data.dig(:signals, :bullish).size}"
    puts "Bearish count: #{data.dig(:signals, :bearish).size}"
  end
end

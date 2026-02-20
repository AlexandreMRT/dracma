# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    quotes = ExporterService.latest_quotes
    rows = quotes.map { |q| ExporterService.format_row(q) }

    @br_stocks   = rows.select { |r| r[:tipo] == "stock" }
    @us_stocks   = rows.select { |r| r[:tipo] == "us_stock" }
    @commodities = rows.select { |r| r[:tipo] == "commodity" }
    @crypto      = rows.select { |r| r[:tipo] == "crypto" }
    @currency    = rows.select { |r| r[:tipo] == "currency" }

    all_stocks = @br_stocks + @us_stocks
    with_1d = all_stocks.select { |r| r[:var_1d] }

    @gainers = with_1d.sort_by { |r| -(r[:var_1d] || 0) }.first(5)
    @losers  = with_1d.sort_by { |r| r[:var_1d] || 0 }.first(5)

    @bullish = all_stocks.select { |r| r[:signal_summary] == "bullish" }
    @bearish = all_stocks.select { |r| r[:signal_summary] == "bearish" }

    @ibov_ytd  = rows.find { |r| r[:ibov_change_ytd] }&.dig(:ibov_change_ytd)
    @sp500_ytd = rows.find { |r| r[:sp500_change_ytd] }&.dig(:sp500_change_ytd)
    @usd_brl   = @currency.first&.dig(:preco_brl)

    @watchlist_data = WatchlistScorer.build(all_stocks)
  end
end

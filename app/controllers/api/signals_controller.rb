# frozen_string_literal: true

module Api
  class SignalsController < BaseController
    def index
      quotes = ExporterService.latest_quotes
      rows = quotes.map { |q| ExporterService.format_row(q) }
      stocks = rows.select { |r| %w[stock us_stock].include?(r[:tipo]) }

      render_json({
        bullish: stocks.select { |r| r[:signal_summary] == "bullish" }.map { |r| r[:ticker] },
        bearish: stocks.select { |r| r[:signal_summary] == "bearish" }.map { |r| r[:ticker] },
        rsi_oversold: stocks.select { |r| r[:signal_rsi_oversold] == 1 }
                            .map { |r| { ticker: r[:ticker], rsi: r[:rsi_14] } },
        rsi_overbought: stocks.select { |r| r[:signal_rsi_overbought] == 1 }
                              .map { |r| { ticker: r[:ticker], rsi: r[:rsi_14] } },
        near_52w_high: stocks.select { |r| r[:signal_52w_high] == 1 }.map { |r| r[:ticker] },
        near_52w_low: stocks.select { |r| r[:signal_52w_low] == 1 }.map { |r| r[:ticker] },
        volume_spike: stocks.select { |r| r[:signal_volume_spike] == 1 }.map { |r| r[:ticker] },
      })
    end
  end
end

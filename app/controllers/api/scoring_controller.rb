# frozen_string_literal: true

module Api
  class ScoringController < BaseController
    def index
      quotes = ExporterService.latest_quotes
      rows = quotes.map { |q| ExporterService.format_row(q) }
      stocks = rows.select { |r| %w[stock us_stock].include?(r[:tipo]) }

      result = WatchlistScorer.build(stocks)
      render_json(result)
    end
  end
end

# frozen_string_literal: true

module Api
  class ScoringController < BaseController
    def index
      stocks = ApiDataService.rows.select { |row| %w[stock us_stock].include?(row[:tipo].to_s) }

      result = WatchlistScorer.build(stocks)
      render_json(result)
    end
  end
end

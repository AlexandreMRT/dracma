# frozen_string_literal: true

module Api
  class ScoringController < BaseController
    def index
      rows = ExporterService.latest_rows
      stocks = rows.select { |r| %w[stock us_stock].include?(r[:tipo]) }

      result = WatchlistScorer.build(stocks)
      render_json(result)
    end
  end
end

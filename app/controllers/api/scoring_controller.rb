# frozen_string_literal: true

module Api
  class ScoringController < BaseController
    def index
      stocks = ApiDataService.rows.select { |row| %w[stock us_stock].include?(row[:tipo].to_s) }
      health = DataHealthChecker.report
      policy = RecommendationPolicy.evaluate(health: health)

      unless policy[:enabled]
        return render_json({ watchlist: [], avoid_list: [], recommendation_policy: policy })
      end

      result = WatchlistScorer.build(stocks)
      render_json(result.merge(recommendation_policy: policy))
    end
  end
end

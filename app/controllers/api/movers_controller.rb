# frozen_string_literal: true

module Api
  class MoversController < BaseController
    def index
      period = params[:period].presence || "1d"
      return render_error("Invalid period", status: :bad_request) unless ApiDataService.mover_key_for(period)

      limit = parse_limit(params[:limit], default: 10)
      return render_error("Invalid limit", status: :bad_request) unless limit

      render_json(ApiDataService.movers(period: period, limit: limit))
    end
  end
end

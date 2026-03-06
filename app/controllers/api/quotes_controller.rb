# frozen_string_literal: true

module Api
  class QuotesController < BaseController
    def index
      date = params[:date] ? Date.parse(params[:date]) : nil
      rows = ApiDataService.rows(quote_date: date)
      render_json({ total: rows.size, quotes: rows })
    rescue Date::Error
      render_error("Invalid date format", status: :bad_request)
    end

    def show
      detail = ApiDataService.asset_detail(params[:id])
      return render_error("Asset not found", status: :not_found) unless detail

      render_json(detail)
    end
  end
end

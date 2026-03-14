# frozen_string_literal: true

module Api
  class QuotesController < BaseController
    def index
      date = params[:date] ? Date.parse(params[:date]) : nil
      rows = ExporterService.sorted_rows(quote_date: date)
      render_json({ total: rows.size, quotes: rows })
    rescue Date::Error
      render_json({ error: "Invalid date format" }, status: :bad_request)
    end
  end
end

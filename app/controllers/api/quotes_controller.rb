# frozen_string_literal: true

module Api
  class QuotesController < BaseController
    def index
      date = params[:date] ? Date.parse(params[:date]) : nil
      quotes = ExporterService.latest_quotes(quote_date: date)
      rows = quotes.map { |q| ExporterService.format_row(q) }
                   .sort_by { |r| [ r[:setor], r[:ticker] ] }
      render_json({ total: rows.size, quotes: rows })
    rescue Date::Error
      render_json({ error: "Invalid date format" }, status: :bad_request)
    end
  end
end

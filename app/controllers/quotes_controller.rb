# frozen_string_literal: true

class QuotesController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : nil
    quotes = ExporterService.latest_quotes(quote_date: @date)
    @rows = quotes.map { |q| ExporterService.format_row(q) }
                  .sort_by { |r| [ r[:setor], r[:ticker] ] }
  end
end

# frozen_string_literal: true

class QuotesController < ApplicationController
  def index
    @date = params[:date] ? Date.parse(params[:date]) : nil
    @rows = ExporterService.sorted_rows(quote_date: @date)
  end
end

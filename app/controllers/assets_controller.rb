# frozen_string_literal: true

class AssetsController < ApplicationController
  def index
    @assets = Asset.order(:sector, :ticker)
    @assets = @assets.where(asset_type: params[:type]) if params[:type].present?
  end

  def show
    @asset = Asset.find(params[:id])
    @quotes = @asset.quotes.order(quote_date: :desc).limit(30)
    @latest = @quotes.first

    return unless @latest

    @row = ExporterService.format_row(@latest)
  end
end

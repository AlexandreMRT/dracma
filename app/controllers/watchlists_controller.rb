# frozen_string_literal: true

class WatchlistsController < ApplicationController
  def index
    @watchlists = current_user.watchlists.order(:ticker)
  end

  def create
    ticker = params[:ticker]&.upcase
    if ticker.present?
      current_user.watchlists.find_or_create_by!(ticker: ticker)
    end
    redirect_to watchlists_path, notice: "#{ticker} added to watchlist"
  end

  def destroy
    wl = current_user.watchlists.find(params[:id])
    wl.destroy!
    redirect_to watchlists_path, notice: "#{wl.ticker} removed from watchlist"
  end
end

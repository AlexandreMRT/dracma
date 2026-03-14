# frozen_string_literal: true

class DashboardController < ApplicationController
  def index
    snapshot = ExporterService.dashboard_snapshot

    @br_stocks = snapshot[:br_stocks]
    @us_stocks = snapshot[:us_stocks]
    @commodities = snapshot[:commodities]
    @crypto = snapshot[:crypto]
    @currency = snapshot[:currency]
    @gainers = snapshot[:gainers]
    @losers = snapshot[:losers]
    @bullish = snapshot[:bullish]
    @bearish = snapshot[:bearish]
    @ibov_ytd = snapshot[:ibov_ytd]
    @sp500_ytd = snapshot[:sp500_ytd]
    @usd_brl = snapshot[:usd_brl]
    @watchlist_data = snapshot[:watchlist_data]
  end
end

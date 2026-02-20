# frozen_string_literal: true

class PositionsController < ApplicationController
  before_action :set_portfolio

  def index
    @positions = PortfolioService.positions(@portfolio)
  end

  def show
    @position = PortfolioService.find_position(@portfolio, params[:id])
    unless @position
      redirect_to portfolio_positions_path(@portfolio), alert: "Position not found"
      return
    end
    @performance = PortfolioService.position_performance(@position)
    @transactions = PortfolioService.ticker_transactions(@portfolio, @position.ticker)
  end

  private

  def set_portfolio
    @portfolio = PortfolioService.find_portfolio(current_user, params[:portfolio_id])
    redirect_to portfolios_path, alert: "Portfolio not found" unless @portfolio
  end
end

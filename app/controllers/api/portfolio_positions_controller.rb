# frozen_string_literal: true

module Api
  class PortfolioPositionsController < BaseController
    before_action :set_portfolio

    def index
      positions = PortfolioService.positions(@portfolio).map { |position| position_payload(position) }
      render_json({ total: positions.size, positions: positions })
    end

    private

    def set_portfolio
      @portfolio = PortfolioService.find_portfolio(current_user, params[:portfolio_id])
      return if @portfolio

      render_error("Portfolio not found", status: :not_found)
    end

    def position_payload(position)
      {
        id: position.id,
        ticker: position.ticker,
        quantity: position.quantity,
        avg_price_brl: position.avg_price_brl,
        notes: position.notes,
        first_purchase_date: position.first_purchase_date,
        last_transaction_date: position.last_transaction_date,
        performance: PortfolioService.position_performance(position)
      }
    end
  end
end

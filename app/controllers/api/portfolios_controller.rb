# frozen_string_literal: true

module Api
  class PortfoliosController < BaseController
    before_action :set_portfolio, only: %i[show update destroy performance]

    def index
      portfolios = PortfolioService.user_portfolios(current_user)
      render_json({ total: portfolios.size, portfolios: portfolios.map { |portfolio| portfolio_payload(portfolio) } })
    end

    def show
      render_json({
        portfolio: portfolio_payload(@portfolio),
        performance: PortfolioService.portfolio_performance(@portfolio)
      })
    end

    def create
      portfolio = PortfolioService.create_portfolio(
        current_user,
        name: portfolio_params[:name].to_s,
        is_default: parse_boolean(portfolio_params[:is_default])
      )
      render_json({ portfolio: portfolio_payload(portfolio) }, status: :created)
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
    end

    def update
      portfolio = PortfolioService.update_portfolio(
        @portfolio,
        name: portfolio_params[:name],
        is_default: portfolio_params.key?(:is_default) ? parse_boolean(portfolio_params[:is_default]) : nil
      )
      render_json({ portfolio: portfolio_payload(portfolio) })
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
    end

    def destroy
      deleted_portfolio = portfolio_payload(@portfolio)
      PortfolioService.delete_portfolio(@portfolio)
      render_json({ deleted: true, portfolio: deleted_portfolio })
    end

    def performance
      render_json(PortfolioService.portfolio_performance(@portfolio))
    end

    private

    def set_portfolio
      @portfolio = PortfolioService.find_portfolio(current_user, params[:id])
      return if @portfolio

      render_error("Portfolio not found", status: :not_found)
    end

    def portfolio_payload(portfolio)
      {
        id: portfolio.id,
        name: portfolio.name,
        is_default: portfolio.is_default,
        positions_count: portfolio.positions.count,
        transactions_count: portfolio.transactions.count,
        created_at: portfolio.created_at,
        updated_at: portfolio.updated_at
      }
    end

    def portfolio_params
      params.fetch(:portfolio, params).permit(:name, :is_default)
    end
  end
end

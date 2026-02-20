# frozen_string_literal: true

class PortfoliosController < ApplicationController
  before_action :set_portfolio, only: [ :show, :edit, :update, :destroy ]

  def index
    @portfolios = PortfolioService.user_portfolios(current_user)
  end

  def show
    @performance = PortfolioService.portfolio_performance(@portfolio)
  end

  def new
    @portfolio = current_user.portfolios.build
  end

  def create
    @portfolio = PortfolioService.create_portfolio(
      current_user,
      name: params[:portfolio][:name],
      is_default: params[:portfolio][:is_default] == "1",
    )
    redirect_to @portfolio, notice: "Portfolio created"
  rescue ActiveRecord::RecordInvalid => e
    @portfolio = current_user.portfolios.build(portfolio_params)
    flash.now[:alert] = e.message
    render :new, status: :unprocessable_entity
  end

  def edit; end

  def update
    PortfolioService.update_portfolio(
      @portfolio,
      name: params[:portfolio][:name],
      is_default: params[:portfolio][:is_default] == "1",
    )
    redirect_to @portfolio, notice: "Portfolio updated"
  rescue ActiveRecord::RecordInvalid => e
    flash.now[:alert] = e.message
    render :edit, status: :unprocessable_entity
  end

  def destroy
    PortfolioService.delete_portfolio(@portfolio)
    redirect_to portfolios_path, notice: "Portfolio deleted"
  end

  private

  def set_portfolio
    @portfolio = PortfolioService.find_portfolio(current_user, params[:id])
    redirect_to portfolios_path, alert: "Portfolio not found" unless @portfolio
  end

  def portfolio_params
    params.require(:portfolio).permit(:name, :is_default)
  end
end

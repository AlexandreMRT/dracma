# frozen_string_literal: true

class TransactionsController < ApplicationController
  before_action :set_portfolio

  def index
    @transactions = PortfolioService.transactions(@portfolio)
  end

  def create
    PortfolioService.add_transaction(
      @portfolio,
      ticker: params[:transaction][:ticker],
      transaction_type: params[:transaction][:transaction_type],
      quantity: params[:transaction][:quantity].to_f,
      price_brl: params[:transaction][:price_brl].to_f,
      fees_brl: params[:transaction][:fees_brl].to_f,
      transaction_date: params[:transaction][:transaction_date],
    )
    redirect_to portfolio_transactions_path(@portfolio), notice: "Transaction recorded"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to portfolio_transactions_path(@portfolio), alert: e.message
  end

  def destroy
    PortfolioService.delete_transaction(@portfolio, params[:id])
    redirect_to portfolio_transactions_path(@portfolio), notice: "Transaction deleted"
  end

  private

  def set_portfolio
    @portfolio = PortfolioService.find_portfolio(current_user, params[:portfolio_id])
    redirect_to portfolios_path, alert: "Portfolio not found" unless @portfolio
  end
end

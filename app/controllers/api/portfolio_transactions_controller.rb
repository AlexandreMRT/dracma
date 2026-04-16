# frozen_string_literal: true

module Api
  class PortfolioTransactionsController < BaseController
    before_action :set_portfolio

    def index
      transactions = PortfolioService.transactions(@portfolio).map { |transaction| transaction_payload(transaction) }
      render_json({ total: transactions.size, transactions: transactions })
    end

    def create
      transaction = PortfolioService.add_transaction(
        @portfolio,
        ticker: transaction_params[:ticker].to_s,
        transaction_type: transaction_params[:transaction_type].to_s,
        quantity: transaction_params[:quantity].to_f,
        price_brl: transaction_params[:price_brl].to_f,
        fees_brl: transaction_params[:fees_brl].presence&.to_f || 0.0,
        broker: transaction_params[:broker].to_s,
        transaction_date: transaction_params[:transaction_date].presence,
      )
      render_json({ transaction: transaction_payload(transaction) }, status: :created)
    rescue ActiveRecord::RecordInvalid => e
      render_error(e.record.errors.full_messages.to_sentence, status: :unprocessable_entity)
    end

    def destroy
      transaction = @portfolio.transactions.find_by(id: params[:id])
      return render_error("Transaction not found", status: :not_found) unless transaction

      deleted_transaction = transaction_payload(transaction)
      PortfolioService.delete_transaction(@portfolio, transaction.id)
      render_json({ deleted: true, transaction: deleted_transaction })
    end

    private

    def set_portfolio
      @portfolio = PortfolioService.find_portfolio(current_user, params[:portfolio_id])
      return if @portfolio

      render_error("Portfolio not found", status: :not_found)
    end

    def transaction_payload(transaction)
      {
        id: transaction.id,
        ticker: transaction.ticker,
        broker: transaction.broker,
        transaction_type: transaction.transaction_type,
        quantity: transaction.quantity,
        price_brl: transaction.price_brl,
        total_brl: transaction.total_brl,
        fees_brl: transaction.fees_brl,
        transaction_date: transaction.transaction_date,
        notes: transaction.notes,
        created_at: transaction.created_at,
        updated_at: transaction.updated_at
      }
    end

    def transaction_params
      params.fetch(:transaction, params).permit(:ticker, :transaction_type, :quantity, :price_brl, :fees_brl, :broker, :transaction_date)
    end
  end
end

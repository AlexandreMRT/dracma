class AddIndexToTransactionsOnPortfolioTickerBrokerDate < ActiveRecord::Migration[8.1]
  def change
    add_index :transactions, [ :portfolio_id, :ticker, :broker, :transaction_date ],
              name: "index_transactions_on_portfolio_ticker_broker_date"
  end
end

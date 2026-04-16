class AddBrokerToPositionsAndTransactions < ActiveRecord::Migration[8.1]
  def change
    add_column :positions, :broker, :string, null: false, default: ""
    add_column :transactions, :broker, :string, null: false, default: ""

    remove_index :positions, [:portfolio_id, :ticker], unique: true
    add_index :positions, [:portfolio_id, :ticker, :broker], unique: true, name: "index_positions_on_portfolio_ticker_broker"
  end
end

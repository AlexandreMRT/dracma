class CreateMarketDataRuns < ActiveRecord::Migration[8.0]
  def change
    create_table :market_data_runs do |t|
      t.string :provider, null: false
      t.string :status, null: false, default: "running"
      t.datetime :started_at, null: false
      t.datetime :finished_at
      t.integer :requested_count, null: false, default: 0
      t.integer :succeeded_count, null: false, default: 0
      t.integer :failed_count, null: false, default: 0
      t.jsonb :failed_tickers, null: false, default: []
      t.text :error_summary

      t.timestamps
    end

    add_index :market_data_runs, :started_at
    add_index :market_data_runs, :status
  end
end

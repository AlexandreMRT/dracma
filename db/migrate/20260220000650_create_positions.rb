class CreatePositions < ActiveRecord::Migration[8.0]
  def change
    create_table :positions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.string :ticker, null: false
      t.float :quantity, default: 0.0
      t.float :avg_price_brl, default: 0.0
      t.datetime :first_purchase_date
      t.datetime :last_transaction_date
      t.text :notes

      t.timestamps
    end
    add_index :positions, [:portfolio_id, :ticker], unique: true
  end
end

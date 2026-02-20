class CreateTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :transactions do |t|
      t.references :portfolio, null: false, foreign_key: true
      t.string :ticker, null: false
      t.integer :transaction_type, null: false
      t.float :quantity, null: false
      t.float :price_brl, null: false
      t.float :total_brl, null: false
      t.float :fees_brl, default: 0.0
      t.datetime :transaction_date, null: false
      t.text :notes

      t.timestamps
    end
  end
end

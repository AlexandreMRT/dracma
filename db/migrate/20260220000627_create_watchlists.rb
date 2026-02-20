class CreateWatchlists < ActiveRecord::Migration[8.0]
  def change
    create_table :watchlists do |t|
      t.references :user, null: false, foreign_key: true, type: :uuid
      t.string :ticker, null: false
      t.text :notes

      t.timestamps
    end
    add_index :watchlists, [:user_id, :ticker], unique: true
  end
end

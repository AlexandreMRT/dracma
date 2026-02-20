class CreateAssets < ActiveRecord::Migration[8.0]
  def change
    create_table :assets do |t|
      t.string :ticker, null: false
      t.string :name, null: false
      t.string :sector, null: false
      t.string :asset_type, null: false
      t.string :unit, default: ""

      t.timestamps
    end
    add_index :assets, :ticker, unique: true
  end
end

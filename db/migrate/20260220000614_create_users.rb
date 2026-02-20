class CreateUsers < ActiveRecord::Migration[8.0]
  def change
    create_table :users, id: :uuid do |t|
      t.string :google_id, null: false
      t.string :email, null: false
      t.string :name, null: false
      t.string :picture_url
      t.string :default_currency, default: "BRL"
      t.datetime :last_login

      t.timestamps
    end
    add_index :users, :google_id, unique: true
    add_index :users, :email, unique: true
  end
end

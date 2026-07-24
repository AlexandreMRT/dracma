class AddGrahamFieldsToQuotes < ActiveRecord::Migration[8.1]
  def change
    add_column :quotes, :graham_number, :float
    add_column :quotes, :graham_multiple, :float
    add_column :quotes, :margin_of_safety_percent, :float
  end
end

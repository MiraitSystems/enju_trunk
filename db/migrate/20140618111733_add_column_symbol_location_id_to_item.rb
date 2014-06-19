class AddColumnSymbolLocationIdToItem < ActiveRecord::Migration
  def change
    add_column :items, :location_symbol_id, :integer
    add_column :items, :statistical_class_id, :integer
    add_index :items, :location_symbol_id
    add_index :items, :statistical_class_id
  end
end

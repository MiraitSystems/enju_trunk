class CreateItemExtexts < ActiveRecord::Migration
  def change
    create_table :item_extexts do |t|
      t.integer :id
      t.string :name
      t.text :value
      t.integer :item_id, :null => false
      t.integer :position, :null => false, :default => 0

      t.timestamps
    end
      add_index :item_extexts, [:item_id, :position], :name => 'item_extext_idx1' 
  end
end

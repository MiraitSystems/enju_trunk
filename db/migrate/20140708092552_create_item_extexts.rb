class CreateItemExtexts < ActiveRecord::Migration
  def change
    create_table :item_extexts do |t|
      t.string :name
      t.text :value
      t.integer :item_id
      t.integer :position
      t.integer :type_id

      t.timestamps
    end
    add_index :item_extexts, [:item_id, :position, :type_id], :name => 'item_extext_idx1'
  end
end

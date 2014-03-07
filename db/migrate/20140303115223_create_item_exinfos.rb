class CreateItemExinfos < ActiveRecord::Migration
  def up
    create_table :item_exinfos do |t|
      t.string :name
      t.string :value
      t.integer :item_id, :null => false
      t.integer :position, :null => false, :default => 0
      t.timestamps
    end
  end

  def down
    drop_table :item_exinfos
  end
end

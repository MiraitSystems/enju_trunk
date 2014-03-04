class CreateIndexToItemExinfos < ActiveRecord::Migration
  def change
    add_index :item_exinfos, [:item_id, :position], :name => 'item_exinfo_index'
  end
end

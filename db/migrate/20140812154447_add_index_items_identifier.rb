class AddIndexItemsIdentifier < ActiveRecord::Migration
  def change
    add_index :items, :identifier, :unique => true
  end
end

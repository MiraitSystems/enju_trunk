class ChangeIndexItemIdentifier < ActiveRecord::Migration
  def change
    remove_index :items, :identifier
    add_index :items, :identifier
  end
end

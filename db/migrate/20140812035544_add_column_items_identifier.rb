class AddColumnItemsIdentifier < ActiveRecord::Migration
  def change
    add_column :items, :identifier, :string
  end
end

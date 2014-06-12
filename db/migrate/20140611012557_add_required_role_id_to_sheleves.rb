class AddRequiredRoleIdToSheleves < ActiveRecord::Migration
  def change
    add_column :shelves, :required_role_id, :integer, :default => "1"
    Shelf.update_all ["required_role_id = ?", "1"]
  end
end

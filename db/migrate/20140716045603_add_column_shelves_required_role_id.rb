class AddColumnShelvesRequiredRoleId < ActiveRecord::Migration
  def change
    add_column :shelves, :required_role_id, :integer, :null => false, :default => 1 
  end
end

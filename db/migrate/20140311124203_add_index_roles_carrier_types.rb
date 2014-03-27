class AddIndexRolesCarrierTypes < ActiveRecord::Migration
  def change
    add_index :roles, [:id, :position], :name => 'roles_index'
    add_index :carrier_types, [:id, :position], :name => 'carrier_types_index'
  end
end

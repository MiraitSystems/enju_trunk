class RemoveColumnFromOrders < ActiveRecord::Migration
  def up
    remove_column :orders, :deliver_place_code_4
    remove_column :orders, :contract_id
  end

  def down
    add_column :orders, :deliver_place_code_4, :integer
    add_column :orders, :contract_id, :integer
  end
end

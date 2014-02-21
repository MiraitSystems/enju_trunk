class RemoveColumnToOrders < ActiveRecord::Migration
  def up
    remove_column :orders, :order_list_id
    remove_column :orders, :purchase_request_id
    remove_column :orders, :position
    remove_column :orders, :state
  end

  def down
    add_column :orders, :state, :string
    add_column :orders, :position, :integer
    add_column :orders, :purchase_request_id, :integer
    add_column :orders, :order_list, :integer
  end
end

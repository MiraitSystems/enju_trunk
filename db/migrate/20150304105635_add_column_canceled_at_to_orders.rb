class AddColumnCanceledAtToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :canceled_at, :timestamp
    add_index :orders, [:order_list_id, :item_id, :canceled_at, :created_at, :accept_id], name: 'order_index1'
  end
end

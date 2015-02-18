class AddColumnAcceptIdToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :accept_id, :integer
    add_index :orders, :accept_id
  end
end

class AddColumnCompletedAtToOrderLists < ActiveRecord::Migration
  def change
    add_column :order_lists, :completed_at, :datetime
    add_index :order_lists, [:bookstore_id, :created_at, :ordered_at, :completed_at], :name => 'order_list_add_index1'
  end
end

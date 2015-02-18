class AddColumnOrderNumberToOrderLists < ActiveRecord::Migration
  def change
    add_column :order_lists, :purchase_order_number, :string
    add_column :order_lists, :your_order_number, :string
  end
end

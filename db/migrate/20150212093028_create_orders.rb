class CreateOrders < ActiveRecord::Migration
  def change
    create_table :orders do |t|
      t.integer :order_list_id
      t.integer :item_id
      t.string :purchase_order_number
      t.string :your_order_number
      t.string :price_string_on_order

      t.timestamps
    end
    add_index :orders, [:order_list_id]
    add_index :orders, [:item_id]
    add_index :orders, [:purchase_order_number]
  end
end

class AddTotalPaymentToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :total_payment, :integer
  end
end

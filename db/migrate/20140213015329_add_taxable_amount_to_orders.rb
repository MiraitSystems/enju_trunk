class AddTaxableAmountToOrders < ActiveRecord::Migration
  def change
    add_column :orders, :taxable_amount, :decimal, :default => 0 , :null =>  false
    add_column :orders, :tax_exempt_amount, :decimal, :default => 0 , :null =>  false
  end
end

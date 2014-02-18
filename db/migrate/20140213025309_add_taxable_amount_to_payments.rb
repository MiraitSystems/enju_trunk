class AddTaxableAmountToPayments < ActiveRecord::Migration
  def change
    add_column :payments, :taxable_amount, :decimal, :default => 0 , :null =>  false
    add_column :payments, :tax_exempt_amount, :decimal, :default => 0 , :null =>  false
  end
end

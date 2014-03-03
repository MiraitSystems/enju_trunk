class RenameCurrencyUnitCodeToPayment < ActiveRecord::Migration
  def up
    rename_column :payments, :currency_unit_code, :currency_id
    change_column :payments, :before_conv_amount_of_payment, :integer
    change_column :payments, :amount_of_payment, :integer
    change_column :payments, :taxable_amount, :integer
    change_column :payments, :tax_exempt_amount, :integer
  end

  def down
    rename_column :payments, :currency_id, :currency_unit_code
    change_column :payments, :before_conv_amount_of_payment, :decimal
    change_column :payments, :amount_of_payment, :decimal
    change_column :payments, :taxable_amount, :decimal
    change_column :payments, :tax_exempt_amount, :decimal
  end
end

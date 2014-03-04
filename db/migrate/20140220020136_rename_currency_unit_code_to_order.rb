class RenameCurrencyUnitCodeToOrder < ActiveRecord::Migration
  def up
    rename_column :orders, :currency_unit_code, :currency_id
    change_column :orders, :prepayment_principal, :integer
    change_column :orders, :yen_imprest, :integer
    change_column :orders, :taxable_amount, :integer
    change_column :orders, :tax_exempt_amount, :integer
    change_column :orders, :unit_price, :integer
  end

  def down
    rename_column :orders, :currency_id, :currency_unit_code
    change_column :orders, :prepayment_principal, :decimal
    change_column :orders, :yen_imprest, :decimal
    change_column :orders, :taxable_amount, :decimal
    change_column :orders, :tax_exempt_amount, :decimal
    change_column :orders, :unit_price, :decimal
  end
end

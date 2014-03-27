class RenameColumenOnOrders < ActiveRecord::Migration
  def up
    rename_column :orders, :discount_commision, :margin_ratio
    rename_column :orders, :prepayment_principal, :original_price
    rename_column :orders, :yen_imprest, :cost
  end
  def down
    rename_column :orders, :margin_ratio, :discount_commision
    rename_column :orders, :original_price, :prepayment_principal
    rename_column :orders, :cost, :yen_imprest
  end
end

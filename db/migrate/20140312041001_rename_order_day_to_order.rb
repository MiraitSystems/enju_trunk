class RenameOrderDayToOrder < ActiveRecord::Migration
  def up
    rename_column :orders, :order_day, :ordered_at
    rename_column :orders, :publication_year, :order_year
    change_column :orders, :ordered_at, :timestamp
    remove_column :orders, :deliver_place_code_5
    add_column :orders, :reference_code_id, :integer
    remove_column :orders, :reason_for_settlements_of_account_code
    add_column :orders, :publisher_type_id, :integer
  end

  def down
    rename_column :orders, :ordered_at, :order_day
    rename_column :orders, :order_year, :publication_year
    change_column :orders, :order_day, :datetime
    remove_column :orders, :reference_code_id
    add_column :orders, :deliver_place_code_5, :integer
    remove_column :orders, :publisher_type_id, :integer
    add_column :orders, :reason_for_settlements_of_account_code, :integer
  end
end

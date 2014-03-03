class RemoveAutoCalculationFlagFromOrders < ActiveRecord::Migration
  def up
    remove_column :orders, :auto_calculation_flag
  end

  def down
    add_column :orders, :auto_calculation_flag, :integer
  end
end

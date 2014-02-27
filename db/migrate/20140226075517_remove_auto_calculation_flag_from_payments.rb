class RemoveAutoCalculationFlagFromPayments < ActiveRecord::Migration
  def up
    remove_column :payments, :auto_calculation_flag
  end

  def down
    add_column :payments, :auto_calculation_flag, :integer
  end
end

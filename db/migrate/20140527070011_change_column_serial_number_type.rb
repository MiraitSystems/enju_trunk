class ChangeColumnSerialNumberType < ActiveRecord::Migration
  def change
    change_column :manifestations, :serial_number, :integer, :limit => 8
  end
end

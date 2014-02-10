class AddColumnFanctionClassIdToUser < ActiveRecord::Migration
  def change
    add_column :users, :function_class_id, :integer
  end
end

class AddColumnOrderIdToAccepts < ActiveRecord::Migration
  def change
    add_column :accepts, :order_id, :integer
  end
end

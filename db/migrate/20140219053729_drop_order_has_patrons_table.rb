class DropOrderHasPatronsTable < ActiveRecord::Migration
  def up
    drop_table :order_has_patrons
  end

  def down
  end
end

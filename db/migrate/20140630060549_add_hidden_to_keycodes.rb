class AddHiddenToKeycodes < ActiveRecord::Migration
  def change
    add_column :keycodes, :hidden, :boolean, null: false, default: false
  end
end

class AddIndexToKeycodes < ActiveRecord::Migration
  def change
    add_index :keycodes, :keyname, :name => 'keycodes_keyname'
    add_index :keycodes, :v, :name => 'keycodes_v'
  end
end

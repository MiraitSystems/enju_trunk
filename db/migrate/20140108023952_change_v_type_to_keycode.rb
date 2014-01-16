class ChangeVTypeToKeycode < ActiveRecord::Migration
  def up
    change_column :keycodes, :v, :string
  end

  def down
    change_column :keycodes, :v, :integer
  end
end

class ChangeColumnToWorkHasTitle < ActiveRecord::Migration
  def up
    change_column(:work_has_titles, :position, :integer, :null => true)
  end

  def down
    change_column(:work_has_titles, :position, :integer, :null => false)
  end
end

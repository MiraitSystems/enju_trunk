class ChangeColumnGradeIdToAgent < ActiveRecord::Migration
  def change
    remove_index :agents, :grade
    remove_column :agents, :grade
    add_column :agents, :grade_id, :integer
    add_index :agents, :grade_id
  end

end

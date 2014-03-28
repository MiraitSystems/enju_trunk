class ChangeColumnGradeToAgent < ActiveRecord::Migration
  def up
    change_column :agents, :grade, :string
  end

  def down
    change_column :agents, :grade, :integer
  end
end

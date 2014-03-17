class AddColumnGradeToAgent < ActiveRecord::Migration
  def change
    add_column :agents, :grade, :integer
  end
end

class AddIndexGradeToAgents < ActiveRecord::Migration
  def change
		add_index :agents, :grade
	end
end

class AddColumnGenderToAgents < ActiveRecord::Migration
  def change
    add_column :agents, :gender_id, :integer, :default => 1, :null => true
    add_index :agents, :gender_id
  end
end

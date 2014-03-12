class AddIndexFrbr < ActiveRecord::Migration
  def change
    add_index :exemplifies, [:manifestation_id, :item_id], :name => 'exemplifies_manifestation_item_index'
    add_index :creates, [:id, :work_id, :position], :name => 'creates_work_index'
    add_index :creates, [:id, :agent_id, :position], :name => 'creates_agent_index'
    add_index :realizes, [:id, :expression_id, :position], :name => 'realizes_expression_index' 
    add_index :realizes, [:id, :agent_id, :position], :name => 'realizes_agent_index' 
    add_index :produces, [:id, :manifestation_id, :position], :name => 'produces_manifestation_index' 
    add_index :produces, [:id, :agent_id, :position], :name => 'produces_agent_index' 
  end
end

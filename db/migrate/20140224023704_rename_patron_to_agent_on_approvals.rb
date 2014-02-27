class RenamePatronToAgentOnApprovals < ActiveRecord::Migration
  def up
    rename_column :approvals, :reception_patron_id, :reception_agent_id    
  end

  def down
    rename_column :approvals, :reception_agent_id, :reception_patron_id    
  end
end

class RenamePatronAliasesToAgentAliases < ActiveRecord::Migration
  def up
    rename_table :patron_aliases, :agent_aliases
    rename_column :agent_aliases, :patron_id, :agent_id
  end

  def down
    rename_table :agent_aliases, :patron_aliases
    rename_column :patron_aliases, :agent_id, :patron_id
  end
end

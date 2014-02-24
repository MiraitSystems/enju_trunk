class RenamePatronToAgent < ActiveRecord::Migration
  def up
    remove_index :creates, [:patron_id]
    remove_index :donates, [:patron_id]
    remove_index :libraries, [:patron_id]
    remove_index :owns, [:patron_id]
    remove_index :participates, [:patron_id]
    remove_index :patron_import_files, [:file_hash]
    remove_index :patron_import_files, [:parent_id]
    remove_index :patron_import_files, [:state]
    remove_index :patron_import_files, [:user_id]
    remove_index :patron_merges, [:patron_id]
    remove_index :patron_merges, [:patron_merge_list_id]
    remove_index :patron_relationships, [:child_id]
    remove_index :patron_relationships, [:parent_id]
    remove_index :patrons, [:country_id]
    remove_index :patrons, [:full_name]
    remove_index :patrons, [:language_id]
    remove_index :patrons, [:patron_identifier]
    remove_index :patrons, [:required_role_id]
    remove_index :patrons, [:user_id]
    remove_index :produces, [:patron_id]
    remove_index :realizes, [:patron_id]
    rename_table :patron_import_files, :agent_import_files
    rename_table :patron_import_results, :agent_import_results
    rename_table :patron_merge_lists, :agent_merge_lists
    rename_table :patron_merges, :agent_merges
    rename_table :patron_relationship_types, :agent_relationship_types
    rename_table :patron_relationships, :agent_relationships
    rename_table :patron_types, :agent_types
    rename_table :patrons, :agents
    rename_column :creates, :patron_id, :agent_id
    rename_column :donates, :patron_id, :agent_id
    rename_column :libraries, :patron_id, :agent_id
    rename_column :libraries, :patron_type, :agent_type
    rename_column :owns, :patron_id, :agent_id
    rename_column :participates, :patron_id, :agent_id
    rename_column :agent_import_files, :patron_import_file_name, :agent_import_file_name
    rename_column :agent_import_files, :patron_import_content_type, :agent_import_content_type
    rename_column :agent_import_files, :patron_import_file_size, :agent_import_file_size
    rename_column :agent_import_files, :patron_import_updated_at, :agent_import_updated_at
    rename_column :agent_import_results, :patron_import_file_id, :agent_import_file_id
    rename_column :agent_import_results, :patron_id, :agent_id
    rename_column :agent_merges, :patron_id, :agent_id
    rename_column :agent_merges, :patron_merge_list_id, :agent_merge_list_id
    rename_column :agent_relationships, :patron_relationship_type_id, :agent_relationship_type_id
    rename_column :agents, :patron_type_id, :agent_type_id
    rename_column :agents, :patron_identifier, :agent_identifier
    rename_column :produces, :patron_id, :agent_id
    rename_column :realizes, :patron_id, :agent_id
    rename_column :reserves, :expiration_notice_to_patron, :expiration_notice_to_agent
    add_index :creates, [:agent_id]
    add_index :donates, [:agent_id]
    add_index :libraries, [:agent_id], :unique => true
    add_index :owns, [:agent_id]
    add_index :participates, [:agent_id]
    add_index :agent_import_files, [:file_hash]
    add_index :agent_import_files, [:parent_id]
    add_index :agent_import_files, [:state]
    add_index :agent_import_files, [:user_id]
    add_index :agent_merges, [:agent_id]
    add_index :agent_merges, [:agent_merge_list_id]
    add_index :agent_relationships, [:child_id]
    add_index :agent_relationships, [:parent_id]
    add_index :agents, [:country_id]
    add_index :agents, [:full_name]
    add_index :agents, [:language_id]
    add_index :agents, [:agent_identifier]
    add_index :agents, [:required_role_id]
    add_index :agents, [:user_id], :unique => true
    add_index :produces, [:agent_id]
    add_index :realizes, [:agent_id]
  end

  def down
    remove_index :realizes, [:agent_id]
    remove_index :produces, [:agent_id]
    remove_index :agents, [:user_id]
    remove_index :agents, [:required_role_id]
    remove_index :agents, [:agent_identifier]
    remove_index :agents, [:language_id]
    remove_index :agents, [:full_name]
    remove_index :agents, [:country_id]
    remove_index :agent_relationships, [:parent_id]
    remove_index :agent_relationships, [:child_id]
    remove_index :agent_merges, [:agent_merge_list_id]
    remove_index :agent_merges, [:agent_id]
    remove_index :agent_import_files, [:user_id]
    remove_index :agent_import_files, [:state]
    remove_index :agent_import_files, [:parent_id]
    remove_index :agent_import_files, [:file_hash]
    remove_index :participates, [:agent_id]
    remove_index :owns, [:agent_id]
    remove_index :libraries, [:agent_id]
    remove_index :donates, [:agent_id]
    remove_index :creates, [:agent_id]
    rename_column :reserves, :expiration_notice_to_agent, :expiration_notice_to_patron
    rename_column :realizes, :agent_id, :patron_id
    rename_column :produces, :agent_id, :patron_id
    rename_column :agents, :agent_identifier, :patron_identifier
    rename_column :agents, :agent_type_id, :patron_type_id
    rename_column :agent_relationships, :agent_relationship_type_id, :patron_relationship_type_id
    rename_column :agent_merges, :agent_merge_list_id, :patron_merge_list_id
    rename_column :agent_merges, :agent_id, :patron_id
    rename_column :agent_import_results, :agent_id, :patron_id
    rename_column :agent_import_results, :agent_import_file_id, :patron_import_file_id
    rename_column :agent_import_files, :agent_import_updated_at, :patron_import_updated_at
    rename_column :agent_import_files, :agent_import_file_size, :patron_import_file_size
    rename_column :agent_import_files, :agent_import_content_type, :patron_import_content_type
    rename_column :agent_import_files, :agent_import_file_name, :patron_import_file_name
    rename_column :participates, :agent_id, :patron_id
    rename_column :owns, :agent_id, :patron_id
    rename_column :libraries, :agent_type, :patron_type
    rename_column :libraries, :agent_id, :patron_id
    rename_column :donates, :agent_id, :patron_id
    rename_column :creates, :agent_id, :patron_id
    rename_table :agents, :patrons
    rename_table :agent_types, :patron_types
    rename_table :agent_relationships, :patron_relationships
    rename_table :agent_relationship_types, :patron_relationship_types
    rename_table :agent_merges, :patron_merges
    rename_table :agent_merge_lists, :patron_merge_lists
    rename_table :agent_import_results, :patron_import_results
    rename_table :agent_import_files, :patron_import_files
    add_index :realizes, [:patron_id], :name => "index_realizes_on_patron_id"
    add_index :produces, [:patron_id], :name => "index_produces_on_patron_id"
    add_index :patrons, [:user_id], :name => "index_patrons_on_user_id", :unique => true
    add_index :patrons, [:required_role_id], :name => "index_patrons_on_required_role_id"
    add_index :patrons, [:patron_identifier], :name => "index_patrons_on_patron_identifier"
    add_index :patrons, [:language_id], :name => "index_patrons_on_language_id"
    add_index :patrons, [:full_name], :name => "index_patrons_on_full_name"
    add_index :patrons, [:country_id], :name => "index_patrons_on_country_id"
    add_index :patron_relationships, [:parent_id], :name => "index_patron_relationships_on_parent_id"
    add_index :patron_relationships, [:child_id], :name => "index_patron_relationships_on_child_id"
    add_index :patron_merges, [:patron_merge_list_id], :name => "index_patron_merges_on_patron_merge_list_id"
    add_index :patron_merges, [:patron_id], :name => "index_patron_merges_on_patron_id"
    add_index :patron_import_files, [:user_id], :name => "index_patron_import_files_on_user_id"
    add_index :patron_import_files, [:state], :name => "index_patron_import_files_on_state"
    add_index :patron_import_files, [:parent_id], :name => "index_patron_import_files_on_parent_id"
    add_index :patron_import_files, [:file_hash], :name => "index_patron_import_files_on_file_hash"
    add_index :participates, [:patron_id], :name => "index_participates_on_patron_id"
    add_index :owns, [:patron_id], :name => "index_owns_on_patron_id"
    add_index :libraries, [:patron_id], :name => "index_libraries_on_patron_id", :unique => true
    add_index :donates, [:patron_id], :name => "index_donates_on_patron_id"
    add_index :creates, [:patron_id], :name => "index_creates_on_patron_id"
  end
end

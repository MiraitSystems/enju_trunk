class RemoveColumnManifestationLanguageId < ActiveRecord::Migration
  def up
    remove_column :manifestations, :language_id
  end

  def down
    add_column :manifestations, :language_id, :integer
  end
end

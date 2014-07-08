class AddColumnTypeIdToManifestationExtext < ActiveRecord::Migration
  def change
    add_column :manifestation_extexts, :type_id, :integer
    remove_index :manifestation_extexts, name: 'manifestation_extext_idx1'
    add_index :manifestation_extexts, [:manifestation_id, :position, :type_id], :name => 'manifestation_extext_idx1'
  end
end

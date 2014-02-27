class CreateIndexIdx1ToManifestationExinfos < ActiveRecord::Migration
  def change
		add_index :manifestation_exinfos, [:manifestation_id, :position], :name => 'manifestation_exinfo_idx1'
  end

end

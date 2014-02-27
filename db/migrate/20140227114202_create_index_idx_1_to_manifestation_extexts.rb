class CreateIndexIdx1ToManifestationExtexts < ActiveRecord::Migration
  def change
		add_index :manifestation_extexts, [:manifestation_id, :position], :name => 'manifestation_extext_idx1'
  end

end

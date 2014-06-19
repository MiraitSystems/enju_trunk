class CreateManifestationHasClassifications < ActiveRecord::Migration
  def change
    create_table :manifestation_has_classifications do |t|
      t.integer :manifestation_id, :null => false
      t.integer :classification_id, :null => false
      t.integer :position

      t.timestamps
    end
    add_index :manifestation_has_classifications, :manifestation_id
    add_index :manifestation_has_classifications, :classification_id
  end
end

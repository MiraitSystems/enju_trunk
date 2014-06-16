class AddColumnNacsisIdentifierToManifestationTypes < ActiveRecord::Migration
  def change
    add_column :manifestation_types, :nacsis_identifier, :string
    add_index :manifestation_types, :nacsis_identifier
  end
end

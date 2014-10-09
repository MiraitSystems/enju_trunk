class AddColumnIconFileameManifestationTypes < ActiveRecord::Migration
  def change
    add_column :manifestation_types, :icon_filename, :string
  end
end

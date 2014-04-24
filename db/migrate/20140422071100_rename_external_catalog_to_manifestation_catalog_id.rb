class RenameExternalCatalogToManifestationCatalogId < ActiveRecord::Migration
  def up
    rename_column :manifestations, :external_catalog, :catalog_id
  end

  def down
    rename_column :manifestations, :catalog_id, :external_catalog
  end
end

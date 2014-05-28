class AddColumnOriginalToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :original, :boolean, :default => false
  end
end

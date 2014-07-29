class AddColumnLocationCategoryIdToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :location_category_id, :integer
  end
end

class AddUseLicenseIdToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :use_license_id, :integer
  end
end

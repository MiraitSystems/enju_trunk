class AddColumnSubCarrierTypeIdToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :sub_carrier_type_id, :integer
    add_index :manifestations, :sub_carrier_type_id
  end
end

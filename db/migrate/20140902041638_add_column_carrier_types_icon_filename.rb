class AddColumnCarrierTypesIconFilename < ActiveRecord::Migration
  def change
    add_column :carrier_types, :icon_filename, :string
  end
end

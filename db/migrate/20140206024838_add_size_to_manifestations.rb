class AddSizeToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :size, :string
  end
end

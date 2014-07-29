class AddJanMagazineToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :jan_magazine, :string
  end
end

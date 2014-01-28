class AddCollectionSourcesFromApprovals < ActiveRecord::Migration
  def change
    add_column :approvals, :collection_sources, :string
  end
end

class ChangePairManifestationIdToOrder < ActiveRecord::Migration
  def up
    change_column :orders, :pair_manifestation_id, :string
  end

  def down
  end
end

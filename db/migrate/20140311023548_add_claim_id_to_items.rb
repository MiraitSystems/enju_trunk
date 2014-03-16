class AddClaimIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :claim_id, :integer
  end
end

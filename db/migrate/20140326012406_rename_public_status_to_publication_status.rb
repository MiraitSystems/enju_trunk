class RenamePublicStatusToPublicationStatus < ActiveRecord::Migration
  def up
    rename_table :public_statuses, :publication_statuses
  end

  def down
  end
end

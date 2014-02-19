# This migration comes from enju_sakura (originally 20140206024838)
class AddSizeToManifestations < ActiveRecord::Migration
  def change
    add_column :manifestations, :size, :string
  end
end

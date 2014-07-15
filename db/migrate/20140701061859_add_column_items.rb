class AddColumnItems < ActiveRecord::Migration
  def change
    add_column :items, :tax_rate_id, :integer
  end
end

class AddColumnLocationCategoryIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :location_category_id, :integer
  end
end

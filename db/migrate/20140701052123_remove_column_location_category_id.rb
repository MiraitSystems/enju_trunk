class RemoveColumnLocationCategoryId < ActiveRecord::Migration
  def change
    remove_column :manifestations, :location_category_id
  end
end

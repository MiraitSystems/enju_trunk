class AddColumnBudgetCategoryIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :budget_category_id, :integer
  end
end

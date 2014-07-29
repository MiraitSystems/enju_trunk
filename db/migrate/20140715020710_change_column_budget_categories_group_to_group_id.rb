class ChangeColumnBudgetCategoriesGroupToGroupId < ActiveRecord::Migration
  def change
    remove_column :budget_categories, :group
    add_column :budget_categories, :group_id, :integer
  end
end

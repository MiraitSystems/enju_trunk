class UpdateBudgets < ActiveRecord::Migration
  def up
    remove_column :budgets, :library_id
    add_column :budgets, :user_id, :integer
    add_column :budgets, :name, :string
    add_column :budgets, :transferred, :integer
    add_column :budgets, :actual, :integer
    add_column :budgets, :implementation, :integer
    add_column :budgets, :estimated_implementation, :integer
    add_column :budgets, :remaining, :integer
    add_column :budgets, :start_date, :date
    add_column :budgets, :end_date, :date
    add_column :budgets, :budget_class, :string
  end

  def down
    add_column :budgets, :library_id, :integer
    remove_column :budgets, :user_id
    remove_column :budgets, :name
    remove_column :budgets, :transferred
    remove_column :budgets, :actual
    remove_column :budgets, :implementation
    remove_column :budgets, :estimated_implementation
    remove_column :budgets, :remaining
    remove_column :budgets, :start_date
    remove_column :budgets, :end_date
    remove_column :budgets, :budget_class
  end
end

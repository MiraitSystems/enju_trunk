class CreateBudgetCategories < ActiveRecord::Migration
  def change
    create_table :budget_categories do |t|    
      t.string :name
      t.string :display_name
      t.string :group
      t.integer :position
      t.timestamps
    end
    add_index :budget_categories, :name, :unique => true
  end
end

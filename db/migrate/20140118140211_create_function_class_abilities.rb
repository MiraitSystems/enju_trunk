class CreateFunctionClassAbilities < ActiveRecord::Migration
  def change
    create_table :function_class_abilities do |t|
      t.integer :function_class_id, null: false
      t.integer :function_id, null: false
      t.integer :ability, default: 0

      t.timestamps
    end
  end
end

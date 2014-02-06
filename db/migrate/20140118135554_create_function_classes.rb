class CreateFunctionClasses < ActiveRecord::Migration
  def change
    create_table :function_classes do |t|
      t.text :display_name, null: false
      t.string :name, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end

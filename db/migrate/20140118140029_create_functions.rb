class CreateFunctions < ActiveRecord::Migration
  def change
    create_table :functions do |t|
      t.string :controller_name, null: false
      t.text :display_name, null: false
      t.text :action_names, null: false
      t.integer :position, null: false

      t.timestamps
    end
  end
end

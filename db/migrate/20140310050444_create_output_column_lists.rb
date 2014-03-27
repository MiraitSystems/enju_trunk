class CreateOutputColumnLists < ActiveRecord::Migration
  def change
    create_table :output_column_lists do |t|
      t.string :name, :null => false
      t.text :column_list

      t.timestamps
    end
  end
end

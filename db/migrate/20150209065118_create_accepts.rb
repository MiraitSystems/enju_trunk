class CreateAccepts < ActiveRecord::Migration
  def change
    create_table :accepts do |t|
      t.integer :basket_id
      t.integer :item_id, :null => false
      t.integer :librarian_id

      t.timestamps
    end

    add_index :accepts, :basket_id
    add_index :accepts, :item_id
  end
end

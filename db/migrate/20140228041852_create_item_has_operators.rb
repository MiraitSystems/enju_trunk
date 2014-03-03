class CreateItemHasOperators < ActiveRecord::Migration
  def change
    create_table :item_has_operators do |t|
      t.integer :id
      t.integer :item_id
      t.integer :user_id
      t.datetime :operated_at
      t.integer :library_id
      t.text :note
      t.timestamp :created_at
      t.timestamp :updated_at

      t.timestamps
    end
  end
end

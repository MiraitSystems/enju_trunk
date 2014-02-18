class CreateTitleTypes < ActiveRecord::Migration
  def change
    create_table :title_types do |t|
      t.integer :id, null: false
      t.string :name, null: false
      t.text :display_name, null: false
      t.text :note
      t.integer :position, null: false
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false

      t.timestamps
    end
  end
end

class CreateWorkHasTitles < ActiveRecord::Migration
  def change
    create_table :work_has_titles do |t|
      t.integer :id, null: false
      t.integer :title_id, null: false
      t.integer :title_type_id, null: false
      t.integer :work_id, null: false
      t.integer :position, null: false
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false

      t.timestamps
    end
  end
end

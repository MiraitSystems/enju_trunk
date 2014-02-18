class CreateWorkHasLanguages < ActiveRecord::Migration
  def change
    create_table :work_has_languages do |t|
      t.integer :work_id, :null => false
      t.integer :language_id, :null => false
      t.integer :position

      t.timestamps
    end
    add_index :work_has_languages, :work_id
    add_index :work_has_languages, :language_id
  end
end

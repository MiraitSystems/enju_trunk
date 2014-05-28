class CreateCatalogs < ActiveRecord::Migration
  def change
    create_table :catalogs do |t|
      t.string :display_name
      t.string :name, :null => false
      t.string :nacsis_identifier, :null => false
      t.string :note

      t.timestamps
    end
    add_index :catalogs, :name, :unique => true
    add_index :catalogs, :nacsis_identifier, :unique => true
  end
end

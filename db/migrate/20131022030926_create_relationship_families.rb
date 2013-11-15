class CreateRelationshipFamilies < ActiveRecord::Migration
  def change
    create_table :relationship_families do |t|
      t.integer :series_statement_id
      t.string :fid
      t.string :display_name, :null => false
      t.text :description
      t.text :note

      t.timestamps
    end
  end
end

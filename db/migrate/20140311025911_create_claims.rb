class CreateClaims < ActiveRecord::Migration
  def change
    create_table :claims do |t|
      t.integer :claim_type_id, :null => false
      t.text :note

      t.timestamps
    end
  end
end

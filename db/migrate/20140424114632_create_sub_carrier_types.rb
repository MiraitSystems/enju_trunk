class CreateSubCarrierTypes < ActiveRecord::Migration
  def change
    create_table :sub_carrier_types do |t|
      t.string :name
      t.string :display_name
      t.integer :carrier_type_id, :null => false
      t.string :nacsis_identifier
      t.string :note
      t.integer :position, :default => 0, :null => false

      t.timestamps
    end
    add_index :sub_carrier_types, :name
    add_index :sub_carrier_types, :carrier_type_id
    add_index :sub_carrier_types, :nacsis_identifier
  end
end

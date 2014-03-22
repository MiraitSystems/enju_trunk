class CreatePublicStatuses < ActiveRecord::Migration
  def change
    create_table :public_statuses do |t|
      t.integer :id, :null => false
      t.string :name, :null => false
      t.string :display_name, :null => false
      t.text :note

      t.timestamps
    end
  end
end

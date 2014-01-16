class CreateKeycodes < ActiveRecord::Migration
  def change
    create_table :keycodes do |t|
      t.string :name
      t.string :display_name
      t.integer :v
      t.string :keyname
      t.datetime :started_at
      t.datetime :ended_at

      t.timestamps
    end
  end
end

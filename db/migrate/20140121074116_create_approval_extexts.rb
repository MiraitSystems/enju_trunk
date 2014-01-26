class CreateApprovalExtexts < ActiveRecord::Migration
  def change
    create_table :approval_extexts do |t|
      t.text :value
      t.integer :approval_id, null: false
      t.integer :position, null: false, defoult: 1
      t.datetime :created_at
      t.datetime :updated_at
      t.integer :created_by
      t.string :state
      t.datetime :comment_at

      t.timestamps
    end
  end
end

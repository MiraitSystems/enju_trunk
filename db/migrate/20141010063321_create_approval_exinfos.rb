class CreateApprovalExinfos < ActiveRecord::Migration
  def change
    create_table :approval_exinfos do |t|
      t.string :name
      t.string :value
      t.integer :approval_id, null: false
      t.integer :position, null: false, :default => 0
      t.timestamps
    end
    add_index :approval_exinfos, [:approval_id, :position], :name => 'approval_exinfo_idx1'
  end
end

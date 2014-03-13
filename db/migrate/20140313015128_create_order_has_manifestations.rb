class CreateOrderHasManifestations < ActiveRecord::Migration
  def change
    create_table :order_has_manifestations do |t|
      t.integer :id
      t.integer :order_id, :null => false
      t.integer :manifestation_id, :null => false
      t.timestamp :created_at
      t.timestamp :updated_at

      t.timestamps
    end
  end
end

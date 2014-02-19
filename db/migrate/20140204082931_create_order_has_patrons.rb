class CreateOrderHasPatrons < ActiveRecord::Migration
  def change
    create_table :order_has_patrons do |t|
      t.integer :order_id
      t.integer :patron_id
      t.integer :position

      t.timestamps
    end
  end
end

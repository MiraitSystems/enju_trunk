class AddPaymentIdToItems < ActiveRecord::Migration
  def change
    add_column :items, :payment_id, :integer
  end
end

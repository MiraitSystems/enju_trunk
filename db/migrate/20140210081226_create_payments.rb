class CreatePayments < ActiveRecord::Migration
  def change
    create_table :payments do |t|
      t.integer :order_id, :null => false
      t.datetime :billing_date
      t.integer :manifestation_id, :null => false
      t.integer :currency_unit_code
      t.decimal :currency_rate, :default => 0, :null => false
      t.decimal :discount_commision, :default => 1, :null => false
      t.decimal :before_conv_amount_of_payment, :default => 0, :null => false
      t.decimal :amount_of_payment, :default => 0, :null => false
      t.integer :number_of_payment, :default => 0, :null => false
      t.string :volume_number
      t.text :note
      t.integer :auto_calculation_flag, :default => 0, :null => false
      t.integer :payment_type

      t.timestamps
    end
  end
end

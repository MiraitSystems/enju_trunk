class CreateTaxRates < ActiveRecord::Migration
  def change
    create_table :tax_rates do |t|
      t.string :name, :null => false, :unique => true
      t.string :display_name
      t.decimal :rate, :null => false, :default => 0.0, :precision => 8, :scale => 3
      t.integer :rounding
      t.date :start_date
      t.date :end_date

      t.timestamps
    end
    add_index :tax_rates, :name, :unique => true
    add_index :tax_rates, [:name, :start_date, :end_date], :name => 'tax_rates_index_1'
  end
end

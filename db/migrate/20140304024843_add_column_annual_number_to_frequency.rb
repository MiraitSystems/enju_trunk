class AddColumnAnnualNumberToFrequency < ActiveRecord::Migration
  def change
    add_column :frequencies, :annual_number, :integer
    add_column :frequencies, :freq_days, :integer
  end
end

class AddDateOfDiscontinuanceToManifestation < ActiveRecord::Migration
  def change
    add_column :manifestations, :date_of_discontinuance, :timestamp
    add_column :manifestations, :dis_date, :string
  end
end

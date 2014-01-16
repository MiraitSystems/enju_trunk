class AddNacsisNameMappingToPatrons < ActiveRecord::Migration
  def change
    add_column :patrons, :source, :integer
    add_column :patrons, :marcid, :string
    add_column :patrons, :lcaid, :string
  end
end

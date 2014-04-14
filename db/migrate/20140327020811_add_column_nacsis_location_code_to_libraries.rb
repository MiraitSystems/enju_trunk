class AddColumnNacsisLocationCodeToLibraries < ActiveRecord::Migration
  def change
    add_column :libraries, :nacsis_location_code, :string
  end
end

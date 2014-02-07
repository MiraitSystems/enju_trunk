class AddMarc21ToCountries < ActiveRecord::Migration
  def change
    add_column :countries, :marc21, :string
    add_index :countries, :marc21
  end
end

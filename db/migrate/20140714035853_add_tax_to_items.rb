class AddTaxToItems < ActiveRecord::Migration
  def change
    add_column :items, :tax, :string
    add_column :items, :excluding_tax, :string
  end
end

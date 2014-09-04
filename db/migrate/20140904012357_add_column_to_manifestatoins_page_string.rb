class AddColumnToManifestatoinsPageString < ActiveRecord::Migration
  def change
    add_column :manifestations, :page_string, :string
  end
end

class AddDisplayToRealizeTypes < ActiveRecord::Migration
  def change
    add_column :realize_types, :display, :boolean
  end
end

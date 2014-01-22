class AddDisplayToCreateTypes < ActiveRecord::Migration
  def change
    add_column :create_types, :display, :boolean
  end
end

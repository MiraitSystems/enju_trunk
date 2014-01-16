class AddDisplayToProduceTypes < ActiveRecord::Migration
  def change
    add_column :produce_types, :display, :boolean
  end
end

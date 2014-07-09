class AddPositionToKeycodes < ActiveRecord::Migration
  def change
    add_column :keycodes, :position, :integer, null: false, default: 0
    Keycode.unscoped.order('name ASC, started_at ASC, id ASC').each do |k|
      k.send :add_to_list_bottom
      k.save!
    end
  end
end

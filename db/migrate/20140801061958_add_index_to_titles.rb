class AddIndexToTitles < ActiveRecord::Migration
  def change
    add_index :titles, :title
  end
end

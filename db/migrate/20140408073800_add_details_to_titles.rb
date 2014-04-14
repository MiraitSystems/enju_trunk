class AddDetailsToTitles < ActiveRecord::Migration
  def change
    add_column :titles, :title_alternative, :text
    add_column :titles, :note, :text
    add_column :titles, :nacsis_identifier, :string
    add_index :titles, :nacsis_identifier
  end
end

class AddHeaderTitleToLibraryGroups < ActiveRecord::Migration
  def change
    add_column :library_groups, :header_title, :string
    execute "UPDATE library_groups SET header_title = display_name WHERE display_name IS NOT NULL;"
  end
end

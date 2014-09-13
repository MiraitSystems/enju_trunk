class AddColumnLibraryGroups < ActiveRecord::Migration
  def change
    add_column :library_groups, :title_color, :string
    add_column :library_groups, :list_odd_color, :string
    add_column :library_groups, :list_even_color, :string
    add_column :library_groups, :list_border_color, :string
  end
end

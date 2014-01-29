class ChangeSearchHistoryColumnType < ActiveRecord::Migration
  def up
    change_column :search_histories, :query, :text
  end

  def down
    change_column :search_histories, :query, :string
  end
end

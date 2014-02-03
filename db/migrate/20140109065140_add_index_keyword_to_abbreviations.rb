class AddIndexKeywordToAbbreviations < ActiveRecord::Migration
  def change
    add_index :abbreviations, :keyword, unique: true
  end
end

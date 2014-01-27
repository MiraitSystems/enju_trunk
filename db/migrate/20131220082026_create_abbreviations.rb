class CreateAbbreviations < ActiveRecord::Migration
  def change
    create_table :abbreviations do |t|
      t.string :keyword
      t.string :v

      t.timestamps
    end
  end
end

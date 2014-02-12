class CreateTitles < ActiveRecord::Migration
  def change
    create_table :titles do |t|
      t.integer :id, null: false
      t.string :title, null: false
      t.string :title_transcription
      t.timestamp :created_at, null: false
      t.timestamp :updated_at, null: false

      t.timestamps
    end
  end
end

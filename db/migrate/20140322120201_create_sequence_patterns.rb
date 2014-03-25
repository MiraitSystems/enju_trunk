class CreateSequencePatterns < ActiveRecord::Migration
  def up
    create_table :sequence_patterns do |t|
      t.string :name
      t.integer :volume_param
      t.integer :issue_param
      t.integer :sequence_type
      t.timestamps
    end
  end

  def down
    drop_table :sequence_patterns
  end
end

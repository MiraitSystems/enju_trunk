class AddSequencePatternIdToSeriesStatements < ActiveRecord::Migration
  def change
    add_column :series_statements, :sequence_pattern_id, :integer
  end
end

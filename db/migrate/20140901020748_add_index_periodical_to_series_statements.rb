class AddIndexPeriodicalToSeriesStatements < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute ("UPDATE series_statements SET periodical = false where periodical is null") 
    change_column(:series_statements, :periodical, :boolean, :null => false, :default => false)
  end

  def down
  end
end

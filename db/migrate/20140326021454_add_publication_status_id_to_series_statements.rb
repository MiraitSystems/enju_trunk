class AddPublicationStatusIdToSeriesStatements < ActiveRecord::Migration
  def change
    add_column :series_statements, :publication_status_id, :integer
  end
end

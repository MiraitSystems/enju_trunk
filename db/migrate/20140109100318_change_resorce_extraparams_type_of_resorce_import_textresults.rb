class ChangeResorceExtraparamsTypeOfResorceImportTextresults < ActiveRecord::Migration
  def up
    change_column :resource_import_textresults, :extraparams, :text
  end

  def down
    change_column :resource_import_textresults, :extraparams, :string
  end
end

class AddColumnNacsisIdentifierToItems < ActiveRecord::Migration
  def change
    add_column :items, :nacsis_identifier, :string
  end
end

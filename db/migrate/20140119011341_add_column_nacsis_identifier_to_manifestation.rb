class AddColumnNacsisIdentifierToManifestation < ActiveRecord::Migration
  def change
    add_column :manifestations, :nacsis_identifier, :text, unique: true, null: true
  end
end

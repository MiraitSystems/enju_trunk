class AddIndexNacsisIdentifierToItems < ActiveRecord::Migration
  def change
    add_index :items, :nacsis_identifier
  end
end

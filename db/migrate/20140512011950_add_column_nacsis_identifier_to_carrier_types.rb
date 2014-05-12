class AddColumnNacsisIdentifierToCarrierTypes < ActiveRecord::Migration
  def change
    add_column :carrier_types, :nacsis_identifier, :string
    add_index :carrier_types, :nacsis_identifier
  end
end

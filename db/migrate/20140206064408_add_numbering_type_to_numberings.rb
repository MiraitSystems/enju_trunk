class AddNumberingTypeToNumberings < ActiveRecord::Migration
  def change
    add_column :numberings, :numbering_type, :string
  end
end

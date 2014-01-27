class AddColumnsToPatron < ActiveRecord::Migration
  def change
    add_column    :patrons, :corporate_type_id, :integer
    add_column    :patrons, :place_id , :integer
    add_column    :patrons, :email_2, :text
    add_column    :patrons, :keyperson_1, :string
    add_column    :patrons, :keyperson_2, :string
  end
end

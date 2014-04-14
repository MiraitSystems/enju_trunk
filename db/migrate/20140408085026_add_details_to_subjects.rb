class AddDetailsToSubjects < ActiveRecord::Migration
  def change
    add_column :subjects, :term_alternative, :text
  end
end

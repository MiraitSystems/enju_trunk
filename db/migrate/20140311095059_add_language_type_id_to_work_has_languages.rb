class AddLanguageTypeIdToWorkHasLanguages < ActiveRecord::Migration
  def change
    add_column :work_has_languages, :language_type_id, :integer
  end
end

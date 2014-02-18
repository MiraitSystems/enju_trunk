class MoveManifestationLanguageIdToWorkHasLanguages < ActiveRecord::Migration
  def up
    ActiveRecord::Base.connection.execute(<<-SQL)
      INSERT INTO work_has_languages (work_id, language_id, position, created_at, updated_at) 
      SELECT id, language_id, 1, created_at, updated_at FROM manifestations
    SQL
  end

  def down
  end
end

class CreateRootManifestationForSeriesStatementWithoutRootManifestation < ActiveRecord::Migration
  def up
    SeriesStatement.where("root_manifestation_id IS NULL").each do |s|
      begin
        ActiveRecord::Base.transaction do 
          manifestation = Manifestation.new
          manifestation.periodical_master   = true
          manifestation.periodical          = s.periodical || false
          manifestation.original_title      = s.original_title
          manifestation.title_transcription = s.title_transcription
          manifestation.title_alternative   = s.title_alternative
          manifestation.series_statement = s
          manifestation.save!
          s.root_manifestation = manifestation
          s.save!
        end
      rescue => e
        puts "Failed to create RootManifestation #{s.id}: #{e}"
      end
    end
  end
end

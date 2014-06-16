class ChangeColumnTitleAndTitleTranscriptionTypeToTitles < ActiveRecord::Migration
  def change
    change_column(:titles, :title, :text)
    change_column(:titles, :title_transcription, :text)
  end
end

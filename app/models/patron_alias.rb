class PatronAlias < ActiveRecord::Base
  belongs_to :patron
  attr_accessible :patron_id, :full_name, :full_name_alternative, :full_name_transcription

  validates :full_name, :presence => true
  validates :full_name_alternative, :presence => true
  validates :full_name_transcription, :presence => true
end

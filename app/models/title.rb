class Title < ActiveRecord::Base
  attr_accessible :created_at, :id, :title, :title_transcription, :updated_at, :title_alternative, :note, :nacsis_identifier

  has_many :work_has_titles
  has_many :manifestations, :through => :work_has_titles

  def self.create_with_title_type(manifestation, title_type, attributes)
    title = Title.create(attributes)
    manifestation.work_has_titles.create(:title_id => title.id, :title_type_id => title_type.id) 
  end
end

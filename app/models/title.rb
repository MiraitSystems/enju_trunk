class Title < ActiveRecord::Base
  attr_accessible :created_at, :id, :title, :title_transcription, :updated_at

  has_many :work_has_titles
  has_many :manifestations, :through => :work_has_titles

end

class WorkHasTitle < ActiveRecord::Base
  attr_accessible :position, :title_id, :title_type_id, :work_id, :title, :title_transcription, :title_alternative, :nested
  attr_accessor :title, :title_transcription, :title_alternative, :nested
  
  default_scope :order => 'position'

  belongs_to :manifestation_title, :class_name => 'Title', :foreign_key => 'title_id'
  belongs_to :manifestation
  belongs_to :title_type

  validates_presence_of :work_id, :unless => :nested
  validates_presence_of :title_id, :title_type_id

  before_validation :set_title
  
  def set_title
    return unless self.title
    manifestation_title = Title.where(:title => self.title).first
    manifestation_title = Title.create(:title => self.title, :title_transcription => self.title_transcription, :title_alternative => self.title_alternative) unless manifestation_title
    self.manifestation_title = manifestation_title
  end
   
end

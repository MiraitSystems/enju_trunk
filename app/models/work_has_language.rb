class WorkHasLanguage < ActiveRecord::Base
  attr_accessible :language_id, :position, :work_id, :language_type_id, :nested
  attr_accessor :nested
  belongs_to :language
  belongs_to :language_type
  belongs_to :work, class_name: 'Manifestation'
  validates_presence_of :work, :language, :unless => :nested
  validates_associated :work, :language
  validates_uniqueness_of :language_id, :scope => [:work_id, :language_type_id]
  acts_as_list :scope => :work_id
  after_save :reindex
  after_destroy :reindex

  def reindex
    self.work.try(:index)
  end

end

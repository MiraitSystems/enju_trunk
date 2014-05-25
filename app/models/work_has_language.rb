class WorkHasLanguage < ActiveRecord::Base
  attr_accessible :language_id, :position, :manifestation_id, :language_type_id, :nested
  attr_accessor :nested
  belongs_to :language
  belongs_to :language_type
  belongs_to :manifestation
  validates_presence_of :manifestation, :language, :unless => :nested
  validates_associated :manifestation, :language
  validates_uniqueness_of :language_id, :scope => [:work_id, :language_type_id]
  acts_as_list :scope => :work_id
  after_save :reindex
  after_destroy :reindex

  def reindex
    self.manifestation.try(:index)
  end

end

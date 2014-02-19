class WorkHasLanguage < ActiveRecord::Base
  attr_accessible :language_id, :position, :work_id
  belongs_to :language
  belongs_to :work, :class_name => 'Manifestation'
  validates_presence_of :work, :language
  validates_associated :work, :language
  validates_uniqueness_of :language_id, :scope => :work_id
  acts_as_list :scope => :work_id
end

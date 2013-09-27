class Theme < ActiveRecord::Base
  
  acts_as_list
  default_scope :order => "position"
  attr_accessible :description, :name, :note, :position, :publish
  
  validates_presence_of :name, :position, :publish
  validates_uniqueness_of :name

  PUBLISH_PATTERN = { I18n.t('resource.publish') => 0, I18n.t('resource.closed') => 1 }

end
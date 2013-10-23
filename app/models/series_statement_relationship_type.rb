class SeriesStatementRelationshipType < ActiveRecord::Base
  default_scope :order => 'position'
  attr_accessible :display_name, :note, :position, :typeid

  validates_uniqueness_of :display_name
  validates_presence_of :display_name
  validates_numericality_of :typeid

  acts_as_list

  paginates_per 10 
end

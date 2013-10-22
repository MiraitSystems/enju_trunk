class RelationshipFamily < ActiveRecord::Base
  default_scope :order => 'id desc'
  attr_accessible :description, :display_name, :note

  validates_presence_of :display_name

  paginates_per 10

  searchable do
    text :display_name, :description, :note
  end
  
end

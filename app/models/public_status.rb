class PublicStatus < ActiveRecord::Base
  attr_accessible :display_name, :id, :name, :note

  validates_presence_of :name
  validates_presence_of :display_name
  
  paginates_per 10
end

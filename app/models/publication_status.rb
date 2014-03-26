class PublicationStatus < ActiveRecord::Base
  attr_accessible :display_name, :id, :name, :note

  has_one :series_statement
  validates_presence_of :name
  validates_presence_of :display_name
  
  paginates_per 10
end

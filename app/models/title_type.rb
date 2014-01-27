class TitleType < ActiveRecord::Base
  attr_accessible :created_at, :display_name, :id, :name, :note, :position, :updated_at

  validates :name, :presence => true
  validates :display_name, :presence => true

  paginates_per 10

end

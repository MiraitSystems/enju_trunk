class AcceptType < ActiveRecord::Base
  include MasterModel
  attr_accessible :display_name, :name, :note, :position
  default_scope :order => "position"
  has_many :items
  scope :donate, where(:name => 'donation')
end

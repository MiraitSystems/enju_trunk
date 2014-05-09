class ClaimType < ActiveRecord::Base
  has_many :claims, :dependent => :destroy
  attr_accessible :display_name, :name
 
  validates_presence_of :display_name, :name
  paginates_per 25
end

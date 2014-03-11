class ClaimType < ActiveRecord::Base
  has_many :claims, :dependent => :destroy

  attr_accessible :display_name, :name
end

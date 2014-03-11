class Claim < ActiveRecord::Base
  #belongs_to :item
  has_one :item
  belongs_to :claim_type
  accepts_nested_attributes_for :item
 
  attr_accessible :claim_type_id, :note
end

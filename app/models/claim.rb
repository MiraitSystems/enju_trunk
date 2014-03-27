class Claim < ActiveRecord::Base
  has_one :item
  belongs_to :claim_type
 
  attr_accessible :claim_type_id, :note

end

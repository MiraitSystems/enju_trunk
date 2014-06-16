class Claim < ActiveRecord::Base
  has_one :item
  belongs_to :claim_type
 
  attr_accessible :claim_type_id, :note
  validates_presence_of :claim_type_id
  before_validation :check_attributes

  def check_attributes
    if self.id
      self.destroy if self.claim_type_id.blank? && self.note.blank?
    end
  end
end

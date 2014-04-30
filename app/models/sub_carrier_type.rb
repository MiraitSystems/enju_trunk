class SubCarrierType < ActiveRecord::Base
  include MasterModel
  default_scope :order => "position"

  belongs_to :carrier_type
  has_many :manifestation

  attr_accessible :carrier_type_id, :display_name, :nacsis_identifier, :name, :note, :position

  validates_presence_of :display_name

end

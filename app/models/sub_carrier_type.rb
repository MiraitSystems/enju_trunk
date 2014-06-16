class SubCarrierType < ActiveRecord::Base
  default_scope :order => "position"

  belongs_to :carrier_type
  has_many :manifestation

  attr_accessible :carrier_type_id, :display_name, :nacsis_identifier, :name, :note, :position

  validates_uniqueness_of :name, :scope => :carrier_type_id
  validates_presence_of :name
  validates_presence_of :carrier_type_id

  acts_as_list

end

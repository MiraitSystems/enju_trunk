class ManifestationExtext < ActiveRecord::Base
  attr_accessible :manifestation_id, :name, :display_name, :position, :value, :type_id
 
  belongs_to :manifestation

  acts_as_list :scope => [:manifestation_id, :name]
  default_scope :order => "position ASC"

  has_paper_trail
end

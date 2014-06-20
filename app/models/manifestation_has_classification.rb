class ManifestationHasClassification < ActiveRecord::Base
  attr_accessible :manifestation_id, :classification_id
  belongs_to :manifestation
  belongs_to :classification
  
  acts_as_list :scope => :manifestation
  
  validates_associated :manifestation, :classification
  validates_presence_of :manifestation, :classification
  validates_uniqueness_of :classification_id, :scope => :manifestation_id
end

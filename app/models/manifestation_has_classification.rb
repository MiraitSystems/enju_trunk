class ManifestationHasClassification < ActiveRecord::Base
  attr_accessible :manifestation_id, :position, :classification_id
  belongs_to :classification
  belongs_to :classification_type
  belongs_to :manifestation
  validates_presence_of :manifestation, :classification
  validates_associated :manifestation, :classification
  validates_uniqueness_of :manifestation_id, :scope => [:classification_id, :classification_type_id]
  #acts_as_list :scope => :manifestation_id
  after_save :reindex
  after_destroy :reindex

  def reindex
    self.manifestation.try(:index)
  end

  def self.new_objs(whl_ary)
    list = []
    whl_ary.each do |whl|
      manifestation_has_classification = self.new(whl)
      list << manifestation_has_classification
    end
    return list
  end

  def self.create_attrs(classification_ids, classification_type_ids)
    return [] if classification_ids.blank? || (classification_type_ids.blank?) ||  ( classification_ids.size != classification_type_ids.size)
    list = []
    classification_ids.zip(classification_type_ids).each do |classification_id, classification_type_id|
      whl = {}
      whl[:classification_id] = classification_id.to_i
      whl[:classification_type_id] = classification_type_id.to_i
      # logger.error "############# work_has_languages = #{whl} ##############"
      list << whl
    end
    return list
  end

end

class WorkHasLanguage < ActiveRecord::Base
  attr_accessible :language_id, :position, :work_id, :language_type_id
  belongs_to :language
  belongs_to :language_type
  belongs_to :work, :class_name => 'Manifestation'
  validates_presence_of :work, :language
  validates_associated :work, :language
  validates_uniqueness_of :work_id, :scope => [:language_id, :language_type_id]
  acts_as_list :scope => :work_id
  after_save :reindex
  after_destroy :reindex

  def reindex
    self.work.try(:index)
  end

  def self.new_objs(whl_ary)
    list = []
    whl_ary.each do |whl|
      work_has_language = self.new(whl)
      list << work_has_language
    end
    return list
  end

  def self.create_attrs(language_ids, language_type_ids)
    return [] if language_ids.blank? || (language_type_ids.blank?) ||  ( language_ids.size != language_type_ids.size)
    list = []
    language_ids.zip(language_type_ids).each do |language_id ,language_type_id|
      whl = {}
      whl[:language_id] = language_id.to_i
      whl[:language_type_id] = language_type_id.to_i
      # logger.error "############# work_has_languages = #{whl} ##############"
      list << whl
    end
    return list
  end

end

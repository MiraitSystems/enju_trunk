class WorkHasLanguage < ActiveRecord::Base
  attr_accessible :language_id, :position, :work_id
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

  def self.add(language_ids, language_type_ids)
    return [] if language_ids.blank? || ( language_ids.size != language_type_ids.size)
    list = []
    language_ids.each_with_index do |language_id ,i|
      whl = self.new
      whl.language = Language.find(language_id)
      whl.language_type = LanguageType.find(language_type_ids[i])
      list << whl
    end
    return list
  end
end

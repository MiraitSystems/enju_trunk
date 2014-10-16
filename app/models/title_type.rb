class TitleType < ActiveRecord::Base
  attr_accessible :created_at, :display_name, :id, :name, :note, :position, :updated_at
  acts_as_list

  has_one :work_has_title

  validates :name, :presence => true
  validates :display_name, :presence => true

  paginates_per 10

  def self.find_or_create_by_name(name)
    title_type = TitleType.where(:name => name).first
    title_type = TitleType.create!(:name => name, :display_name => name) unless title_type
    return title_type
  end

  def destroy?
    return false if WorkHasTitle.where(:title_type_id => self.id).first
    return true
  end

end

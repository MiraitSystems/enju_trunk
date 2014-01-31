class TitleType < ActiveRecord::Base
  attr_accessible :created_at, :display_name, :id, :name, :note, :position, :updated_at

  has_one :work_has_title

  validates :name, :presence => true
  validates :display_name, :presence => true

  paginates_per 10

  def destroy?
    return false if WorkHasTitle.where(:title_type_id => self.id).first
    return true
  end

end

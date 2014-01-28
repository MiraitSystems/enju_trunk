class WorkHasTitle < ActiveRecord::Base
  attr_accessible :created_at, :id, :position, :title_id, :title_type_id, :updated_at, :work_id,
  :manifestation_title

  belongs_to :manifestation_title, :class_name => 'Title', :foreign_key => 'title_id'
  accepts_nested_attributes_for :manifestation_title
  belongs_to :manifestation, :class_name => 'Manifestation', :foreign_key => 'work_id'


end

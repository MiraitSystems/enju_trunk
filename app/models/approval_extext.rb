class ApprovalExtext < ActiveRecord::Base
  attr_accessible :approval_id, :created_at, :position, :updated_at, :value, :created_by, :state, :comment_at, :name

  belongs_to :approval
  belongs_to :create_user, :class_name => "User", :foreign_key => :created_by

  acts_as_list :scope => [:approval_id, :name]
  default_scope :order => "position ASC"
  has_paper_trail
end

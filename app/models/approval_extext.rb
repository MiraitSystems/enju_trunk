class ApprovalExtext < ActiveRecord::Base
  attr_accessible :approval_id, :created_at, :position, :updated_at, :value, :created_by, :state, :comment_at

  belongs_to :approval
  belongs_to :create_user, :class_name => "User", :foreign_key => :created_by

end

class ApprovalExinfo < ActiveRecord::Base
  attr_accessible :approval_id, :name, :value, :position 

  acts_as_list :scope => [:approval_id, :name]
  default_scope order: "position"
  belongs_to :approval

  has_paper_trail

  belongs_to :keycode, class_name: "Keycode", foreign_key: :value
end

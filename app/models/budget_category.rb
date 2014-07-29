class BudgetCategory < ActiveRecord::Base
  acts_as_list
  default_scope :order => :position
  has_many :manifestation
  validates_uniqueness_of :name, :case_sensitive => false, :scope => :group_id
  validates_presence_of :name, :display_name
end

class BudgetCategory < ActiveRecord::Base
  include MasterModel
  has_many :manifestation
  validates_presence_of :group
end

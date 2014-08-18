require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'produce')
class Produce < ActiveRecord::Base
  attr_accessible :produce_type_id
  has_paper_trail
  scope :readable_by, lambda{|user| {:include => :agent, :conditions => ['agents.required_role_id <= ?', user.role.id]}}

end


require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'realize')
class Realize < ActiveRecord::Base
  belongs_to :agent
  validates_associated :agent
  after_save :reindex
  after_destroy :reindex
  attr_accessible :realize_type_id
  scope :readable_by, lambda{|user| {:include => :agent, :conditions => ['agents.required_role_id <= ?', user.role.id]}}

  paginates_per 10

  has_paper_trail

  def reindex
    agent.try(:index)
    expression.try(:index)
  end
end

# == Schema Information
#
# Table name: realizes
#
#  id            :integer         not null, primary key
#  agent_id     :integer         not null
#  expression_id :integer         not null
#  position      :integer
#  type          :string(255)
#  created_at    :datetime
#  updated_at    :datetime
#


require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'create')
class Create < ActiveRecord::Base
  belongs_to :agent
  belongs_to :create_type
  validates_associated :agent
  after_save :reindex
  after_destroy :reindex
  attr_accessible :create_type_id
  scope :readable_by, lambda{|user| {:include => :agent, :conditions => ['agents.required_role_id <= ?', user.try(:role).try(:id) || Role.find_by_name('Guest').id]}}

  paginates_per 10

  has_paper_trail

  def reindex
    agent.try(:index)
    work.try(:index)
  end

end

# == Schema Information
#
# Table name: creates
#
#  id         :integer         not null, primary key
#  agent_id  :integer         not null
#  work_id    :integer         not null
#  position   :integer
#  type       :string(255)
#  created_at :datetime
#  updated_at :datetime
#


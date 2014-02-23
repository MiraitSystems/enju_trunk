class AgentMergeList < ActiveRecord::Base
  has_many :agent_merges, :dependent => :destroy
  has_many :agents, :through => :agent_merges
  validates_presence_of :title

  paginates_per 10

  def merge_agents(selected_agent)
    self.agents.each do |agent|
      Create.where(:agent_id => agent.id).each do |create|
        create.update_attributes(:agent_id => selected_agent.id)
      end
      Realize.where(:agent_id => agent.id).each do |realize|
        realize.update_attributes(:agent_id => selected_agent.id)
      end
      Produce.where(:agent_id => agent.id).each do |produce|
        produce.update_attributes(:agent_id => selected_agent.id)
      end
      Own.where(:agent_id => agent.id).each do |own|
        own.update_attributes(:agent_id => selected_agent.id)
      end
      Donate.where(:agent_id => agent.id).each do |donate|
        donate.update_attributes(:agent_id => selected_agent.id)
      end
      agent.destroy unless agent == selected_agent
    end
  end
end

# == Schema Information
#
# Table name: agent_merge_lists
#
#  id         :integer         not null, primary key
#  title      :string(255)
#  created_at :datetime
#  updated_at :datetime
#


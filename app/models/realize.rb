require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'realize')
class Realize < ActiveRecord::Base
  belongs_to :agent
  validates_associated :agent
  after_save :reindex
  after_destroy :reindex
  attr_accessible :realize_type_id

  paginates_per 10

  has_paper_trail

  def reindex
    agent.try(:index)
    expression.try(:index)
  end

  def self.new_from_instance(realizes, del_contributors, add_contributors)
    editing_realizes = realizes.dup
    editing_realizes.reject!{|c| del_contributors.include?(c.agent_id.to_s)}
    if SystemConfiguration.get("add_only_exist_agent")
      editing_realizes += self.new_attrs_with_agent(add_contributors)
    else
      editing_realizes += self.new_attrs_with_agent(add_contributors)
    end
    editing_realizes.uniq{|r| r.agent_id}
  end

  def self.new_attrs(agent_ids, type_ids)
    return [] if agent_ids.blank?
    lists = []
    agent_ids.zip(type_ids).each do |agent_id ,type_id|
      realize = {}
      realize[:agent_id] = agent_id
      realize[:realize_type_id] = type_id
      lists << new(realize)
    end
    lists
  end

  def self.new_attrs_with_agent(agent_infos)
    lists = []
    agent_infos.each do |agent_info|
      unless agent_info[:agent_id]
        if agent_info[:full_name]
          agent = Agent.add_agent(agent_info[:full_name], agent_info[:full_name_transcription])
        else
          agent = {}
        end
        agent_info[:agent_id] = agent[:id]
      end
      if agent_info[:agent_id]
        realize = new
        realize.agent_id = agent_info[:agent_id]
        realize.realize_type_id = agent_info[:type_id] ? agent_info[:type_id] : 1
        lists << realize
      end
    end
    lists
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


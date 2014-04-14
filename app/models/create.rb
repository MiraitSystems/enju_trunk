require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'create')
class Create < ActiveRecord::Base
  belongs_to :agent
  belongs_to :create_type
  validates_associated :agent
  after_save :reindex
  after_destroy :reindex
  attr_accessible :create_type_id

  paginates_per 10

  has_paper_trail

  def reindex
    agent.try(:index)
    work.try(:index)
  end

  def self.new_from_instance(creates, del_creators, add_creators)
    editing_creates = creates.dup
    editing_creates.reject!{|c| del_creators.include?(c.agent_id.to_s)}
    if SystemConfiguration.get("add_only_exist_agent")
      editing_creates += self.new_attrs_with_agent(add_creators)
    else
      editing_creates += self.new_attrs_with_agent(add_creators)
    end
    editing_creates.uniq{|c| c.agent_id}
  end

  def self.new_attrs(agent_ids, type_ids)
    return [] if agent_ids.blank?
    lists = []
    agent_ids.zip(type_ids).each do |agent_id ,type_id|
      create = {}
      create[:agent_id] = agent_id
      create[:create_type_id] = type_id
      lists << new(create)
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
        create = new
        create.agent_id = agent_info[:agent_id]
        create.create_type_id = agent_info[:type_id] ? agent_info[:type_id] : 1
        lists << create
      end
    end
    lists
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


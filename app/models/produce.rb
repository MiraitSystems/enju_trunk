require EnjuTrunkFrbr::Engine.root.join('app', 'models', 'produce')
class Produce < ActiveRecord::Base
  attr_accessible :produce_type_id
  has_paper_trail

  def self.new_from_instance(produces, del_publishers, add_publishers)
    editing_produces = produces.dup
    editing_produces.reject!{|c| del_publishers.include?(c.agent_id.to_s)}
    if SystemConfiguration.get("add_only_exist_agent")
      editing_produces += self.new_attrs_with_agent(add_publishers)
    else
      editing_produces += self.new_attrs_with_agent(add_publishers)
    end
    editing_produces.uniq{|r| r.agent_id}
  end

  def self.new_attrs(agent_ids, type_ids)
    return [] if agent_ids.blank?
    lists = []
    agent_ids.zip(type_ids).each do |agent_id ,type_id|
      produce = {}
      produce[:agent_id] = agent_id
      produce[:produce_type_id] = type_id
      lists << new(produce)
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
        produce = new
        produce.agent_id = agent_info[:agent_id]
        produce.produce_type_id = agent_info[:type_id] ? agent_info[:type_id] : 1
        lists << produce
      end
    end
    lists
  end

end


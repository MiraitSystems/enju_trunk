class AgentRelationship < ActiveRecord::Base
  belongs_to :parent, :foreign_key => 'parent_id', :class_name => 'Agent'
  belongs_to :child, :foreign_key => 'child_id', :class_name => 'Agent'
  belongs_to :agent_relationship_type
  validate :check_parent
  validates_presence_of :parent_id, :child_id
  acts_as_list :scope => :parent_id
  scope :select_type_id, lambda { |type_id| where("agent_relationship_type_id = ?", type_id) }
  after_save :reindex
  after_destroy :reindex

  def check_parent
    errors.add(:parent) if parent_id == child_id
    existing_record = AgentRelationship.find(:first, :conditions => ["parent_id = ? AND child_id = ?", child_id, parent_id])
    unless existing_record.blank?
      errors.add(:parent)
    end
  end

  def reindex
    self.parent.index
    self.child.index
  end

  def self.count_relationship(agent_id, relation_type_id, parent_child_relationship)
    return 0 if agent_id.blank?
    if relation_type_id.blank? && parent_child_relationship.blank?
      self.where("parent_id = ? OR child_id = ?", agent_id, agent_id).count
    else
      unless relation_type_id.blank?
        case parent_child_relationship
        when 'p'
          self.where("parent_id = ? AND agent_relationship_type_id = ?", agent_id, relation_type_id).count
        when 'c'
          self.where("child_id = ? AND agent_relationship_type_id = ?", agent_id, relation_type_id).count
        else
          0
        end
      end
    end
  end
end

# == Schema Information
#
# Table name: agent_relationships
#
#  id                          :integer         not null, primary key
#  parent_id                   :integer
#  child_id                    :integer
#  agent_relationship_type_id :integer
#  created_at                  :datetime
#  updated_at                  :datetime
#  position                    :integer
#


class AgentAlias < ActiveRecord::Base
  belongs_to :agent
  attr_accessible :agent_id, :full_name, :full_name_alternative, :full_name_transcription
  default_scope :order => "id ASC" 

#  validates :agent_id, :presence => true
#  validates :full_name, :presence => true
#  validates :full_name_alternative
#  validates :full_name_transcription
end

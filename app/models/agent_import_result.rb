class AgentImportResult < ActiveRecord::Base
  default_scope :order => 'agent_import_results.id DESC'
  scope :file_id, proc{|file_id| where(:agent_import_file_id => file_id)}
  scope :failed, where(:agent_id => nil)

  belongs_to :agent_import_file
  belongs_to :agent
  belongs_to :user

  validates_presence_of :agent_import_file_id

  def self.get_agent_import_results_tsv(agent_import_results)
    data = String.new
    data << "\xEF\xBB\xBF".force_encoding("UTF-8") + "\n"
    columns = [
      [:agent, 'activerecord.models.agent'],
      [:user, 'activerecord.models.user'],
      [:error_msg, 'activerecord.attributes.agent_import_result.error_msg']
    ]

    # title column
    row = columns.map {|column| I18n.t(column[1])}
    if SystemConfiguration.get("set_output_format_type") == false
      data << '"'+row.join("\",\"")+"\"\n"
    else
      data << '"'+row.join("\"\t\"")+"\"\n"
    end

    agent_import_results.each do |agent_import_result|
      row = []
      columns.each do |column|
        case column[0]
        when :agent
          agent = ""
          agent = agent_import_result.agent.full_name if agent_import_result.agent
          row << agent
        when :user
          user = ""
          user = agent_import_result.user.username if agent_import_result.user 
          row << user
        when :error_msg
          error_msg = ""
          error_msg = agent_import_result.error_msg
          row << error_msg
        end
      end
      if SystemConfiguration.get("set_output_format_type") == false
        data << '"' + row.join("\",\"") + "\"\n"
      else
        data << '"' + row.join("\"\t\"") + "\"\n"
      end
    end
    return data
  end
end

# == Schema Information
#
# Table name: agent_import_results
#
#  id                    :integer         not null, primary key
#  agent_import_file_id :integer
#  agent_id             :integer
#  user_id               :integer
#  body                  :text
#  created_at            :datetime
#  updated_at            :datetime
#


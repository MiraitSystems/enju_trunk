module AgentsHelper
  include PictureFilesHelper
  def agent_custom_book_jacket(agent)
    link = ''
    agent.picture_files.each_with_index do |picture_file, i|
      if i == 0
        link += link_to(show_image(picture_file, :size => :thumb), picture_file_path(picture_file, :format => picture_file.extname), :rel => "agent_#{agent.id}")
      else
        link += '<span style="display: none">' + link_to(show_image(picture_file, :size => :thumb), picture_file_path(picture_file, :format => picture_file.extname), :rel => "agent_#{agent.id}") + '</span>'
      end
    end
    link.html_safe
  end

  def agent_relationship_anyone(agent, id)
    agent_relationship = agent.children.find_by_child_id(id)
    agent_relationship = agent.parents.find_by_parent_id(id) unless agent_relationship
    return agent_relationship
  end

  def agent_relationship_type_show(agent, id)
    pr = agent.parents.find_by_parent_id(id)
    return get_detail_name(pr.agent_relationship_type, 'p', 'c') if pr
    pr = agent.children.find_by_child_id(id)
    return get_detail_name(pr.agent_relationship_type, 'c', 'p') if pr
    return nil
  end

  def corporate_types
    return Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", corporate_types_key, Time.zone.now) rescue nil
  end

  def agent_relationship_type_facet(select_id, select_relation = nil, current_type, current_relation, display_name, count)
    string = ''
    current = true if select_id == current_type && (select_relation.nil? || select_relation == current_relation)
    string << "<strong>" if current
    string << link_to("#{display_name} (" + count.to_s + ")",
                      url_for(params.merge(
                        :page => nil,
                        :agent_relationship_type => select_id,
                        :parent_child_relationship => select_relation,
                        :view => nil)))
    string << "</strong>" if current
    string.html_safe
  end

  def agent_type_facet(agent_type, current_agent_type, facet)
    string = ''
    current = true if current_agent_type.to_s == agent_type.name.to_s
    string << "<strong>" if current
    string << link_to("#{agent_type.display_name.localize} (" + facet.count.to_s + ")", 
      url_for(params.merge(
        :page        => nil, 
        :agent_type => agent_type.name, 
        :view        => nil)))
    string << "</strong>" if current
    string.html_safe
  end

  def set_agent_params(agent_id = nil)
    param_hash = Hash.new
    param_hash.store('agent_id', agent_id)
    param_hash.store('agent_relationship_type', params[:agent_relationship_type])
    param_hash.store('parent_child_relationship', params[:parent_child_relationship])
    param_hash.store('agent_type', params[:agent_type])
    param_hash.store('page', params[:page])
    return param_hash
  end
end

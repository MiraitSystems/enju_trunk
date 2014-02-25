class AgentRelationshipsController < InheritedResources::Base
  load_and_authorize_resource
  before_filter :prepare_options, :except => [:index, :destroy]
  before_filter :parent_child_delete, :only => [:destroy]

  def parent_child_delete
    # レコード削除時、親子レコードが相互にある場合（通常発生しないが）、
    # 対象レコードのparent_idとchild_idを入れ替えて検索し、対象レコードを削除
    pr_result = AgentRelationship.find(params[:id])
    AgentRelationship.where(["parent_id = ? AND child_id = ?", pr_result.child_id, pr_result.parent_id]).destroy_all rescue nil
  end

  def prepare_options
    @agent_relationship_types = AgentRelationshipType.all
  end

  def new
    @agent_relationship = AgentRelationship.new(params[:agent_relationship])
    @agent_relationship.parent = Agent.find(params[:agent_id]) rescue nil
    @agent_relationship.child = Agent.find(params[:child_id]) rescue nil
  end

  def create
    create! {agent_agents_path(@agent_relationship.parent, :mode => 'show')}
  end

  def update
    @agent_relationship = AgentRelationship.find(params[:id])
    if params[:position]
      @agent_relationship.insert_at(params[:position])
      redirect_to agent_relationships_url
      return
    end
    update! do |format|
      format.html {redirect_to agent_agents_path(params[:agent_id], set_params)}
    end
  end

  def destroy
    destroy! do |format|
      format.html {redirect_to agent_agents_path(params[:agent_id], set_params)}
    end
  end

  def set_params
    if AgentRelationship.count_relationship(params[:agent_id], params[:agent_relationship_type], params[:parent_child_relationship]) == 0
      params[:agent_relationship_type] = nil
      params[:parent_child_relationship] = nil
      params[:agent_type] = nil
    end
    param_hash = Hash.new
    param_hash.store('mode','show')
    param_hash.store('agent_relationship_type', params[:agent_relationship_type])
    param_hash.store('parent_child_relationship', params[:parent_child_relationship])
    param_hash.store('agent_type', params[:agent_type])
    param_hash.store('page', params[:page])
    return param_hash
  end
end

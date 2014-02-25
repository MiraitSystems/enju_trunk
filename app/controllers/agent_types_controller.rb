class AgentTypesController < InheritedResources::Base
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def update
    @agent_type = AgentType.find(params[:id])
    if params[:move]
      move_position(@agent_type, params[:move])
      return
    end
    update!
  end

  def index
    @agent_types = @agent_types.page(params[:page])
  end
end

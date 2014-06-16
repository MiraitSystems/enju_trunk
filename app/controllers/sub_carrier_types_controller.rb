class SubCarrierTypesController < InheritedResources::Base
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def index
    @sub_carrier_types= SubCarrierType.page(params[:page])
  end

  def update
    if params[:move]
      move_position(@sub_carrier_type, params[:move])
      return
    end
    update!
  end
end

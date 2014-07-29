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

  def search_name
    struct_classification = Struct.new(:id, :text)
    if params[:sub_carrier_type_id]
      sub_carrier_type = SubCarrierType.where(id: params[:sub_carrier_type_id]).select("id, display_name, name").first
      result = struct_classification.new(sub_carrier_type.id, "#{sub_carrier_type.display_name}(#{sub_carrier_type.name})")
    else
      result = []
      sub_carrier_types = params[:carrier_type_id].blank? ? SubCarrierType : SubCarrierType.where(:carrier_type_id => params[:carrier_type_id])
      sub_carrier_types = sub_carrier_types.where("name like '%#{params[:search_phrase]}%' OR display_name like '%#{params[:search_phrase]}%'") unless params[:search_phrase].blank?
      sub_carrier_types = sub_carrier_types.select("id, display_name, name").limit(10) || []
      sub_carrier_types.each do |sub_carrier_type|
        result << struct_classification.new(sub_carrier_type.id, "#{sub_carrier_type.name}: #{sub_carrier_type.display_name}")
      end 
    end 
    respond_to do |format|
      format.json { render :text => result.to_json }
    end 
  end
end

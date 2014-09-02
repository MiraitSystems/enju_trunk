class CarrierTypesController < InheritedResources::Base
  add_breadcrumb "I18n.t('activerecord.models.carrier_type')", 'carrier_types_path'
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.carrier_type'))", 'new_carrier_type_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.carrier_type'))", 'edit_carrier_type_path(params[:id])', :only => [:edit, :update]
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource
  before_filter :prepare_options, :only => [:new, :edit]

  def update
    @carrier_type = CarrierType.find(params[:id])
    if params[:move]
      move_position(@carrier_type, params[:move])
      return
    end
    update!
  end

  def prepare_options
    spec = Gem::Specification.find_by_name("enju_trunk")
    gem_root = spec.gem_dir
    files = Dir.glob("#{gem_root}/app/assets/images/icons/carrier_type_*.png")
    @icon_files = files.inject([]) {|a, file| a << File.basename(file)} 
  end
end

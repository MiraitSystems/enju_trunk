class ManifestationTypesController < InheritedResources::Base
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource
  before_filter :prepare_options, :only => [:new, :edit]

  def update
    @manifestation_types = ManifestationType.find(params[:id])
    if params[:move]
      move_position(@manifestation_types, params[:move])
      return
    end
    update!
  end

  def prepare_options
    spec = Gem::Specification.find_by_name("enju_trunk")
    gem_root = spec.gem_dir
    files = Dir.glob("#{gem_root}/app/assets/images/icons/manifestation_type_*.png")
    @icon_files = files.inject([]) {|a, file| a << File.basename(file)} 
  end 
end

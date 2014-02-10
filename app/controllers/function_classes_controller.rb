class FunctionClassesController < InheritedResources::Base
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.function_class'))", 'function_classes_path', :only => :index
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.function_class'))", 'new_function_class_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.function_class'))", 'edit_function_class_path(params[:id])', :only => [:edit, :update]
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def update
    redirect_to function_classes_url    
  end
 
  def create
    redirect_to function_classes_url
  end
end

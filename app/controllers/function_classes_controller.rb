class FunctionClassesController < InheritedResources::Base
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.function_class'))", 'function_classes_path', :only => :index
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.function_class'))", 'new_function_class_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.function_class'))", 'edit_function_class_path(params[:id])', :only => [:edit, :update]
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def update
    respond_to do |format|
      if @function_class.update_attributes(params[:function_class])
        flash[:notice] =  t('controller.successfully_updated', :model => t('activerecord.models.function_class'))
        format.html { redirect_to function_classes_url }
      else
        format.html { render :action => "edit" }
      end
    end
  end
 
  def create
    @function_class = FunctionClass.new(params[:function_class])
    respond_to do |format|
      if @function_class.valid?
        @function_class.save!
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.function_class'))
        format.html { redirect_to function_classes_url }
      else
        format.html { render :action => "new" }
      end
    end
  end
end

class PublicStatusesController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.public_status'))", 'public_statuses_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.public_status'))", 'public_status_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.public_status'))", 'new_public_status_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.public_status'))", 'edit_public_status_path(params[:id])', :only => [:edit, :update]

  before_filter :check_client_ip_address
  load_and_authorize_resource

  def index
    @public_statuses = PublicStatus.page(params[:page])
  end

  def new
    @public_status = PublicStatus.new
  end

  def create
    @public_status = PublicStatus.new(params[:public_status])

    respond_to do |format|
      if @public_status.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.public_status'))
        format.html { redirect_to @public_status }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @public_status = PublicStatus.find(params[:id])
  end

  def update
    @public_status = PublicStatus.find(params[:id])

    respond_to do |format|
      if @public_status.update_attributes(params[:public_status])
         flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.public_status'))
        format.html { redirect_to @public_status }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @public_status = PublicStatus.find(params[:id])
  end

  def destroy
    @public_status = PublicStatus.find(params[:id])
    respond_to do |format|
      @public_status.destroy
      format.html { redirect_to(public_statuses_url) }
    end
  end

end


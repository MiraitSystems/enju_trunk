class PublicationStatusesController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.publication_status'))", 'publication_statuses_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.publication_status'))", 'publication_status_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.publication_status'))", 'new_publication_status_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.publication_status'))", 'edit_publication_status_path(params[:id])', :only => [:edit, :update]

  before_filter :check_client_ip_address
  load_and_authorize_resource

  def index
    @publication_statuses = PublicationStatus.page(params[:page])
  end

  def new
    @publication_status = PublicationStatus.new
  end

  def create
    @publication_status = PublicationStatus.new(params[:publication_status])

    respond_to do |format|
      if @publication_status.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.publication_status'))
        format.html { redirect_to @publication_status }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @publication_status = PublicationStatus.find(params[:id])
  end

  def update
    @publication_status = PublicationStatus.find(params[:id])

    respond_to do |format|
      if @publication_status.update_attributes(params[:publication_status])
         flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.publication_status'))
        format.html { redirect_to @publication_status }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @publication_status = PublicationStatus.find(params[:id])
  end

  def destroy
    @publication_status = PublicationStatus.find(params[:id])
    respond_to do |format|
      @publication_status.destroy
      format.html { redirect_to(publication_statuses_url) }
    end
  end

end


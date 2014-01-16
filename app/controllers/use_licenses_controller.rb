class UseLicensesController < ApplicationController
  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def new
    @use_license = UseLicense.new

    respond_to do |format|
      format.html
      format.json { render :json => @use_license }
    end
  end

  def edit
  end

  def create
    @use_license = UseLicense.new(params[:use_license])

    respond_to do |format|
      if @use_license.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.use_license'))
        format.html { redirect_to(@use_license) }
        format.json { render :json => @use_license, :status => :created, :location => @use_license }
      else
        format.html { render :action => "new" }
        format.json { render :json => @use_license.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    respond_to do |format|
      if @use_license.update_attributes(params[:use_license])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.use_license'))
        format.html { redirect_to use_license_url(@use_license) }
        format.json { head :no_content }
      else
        format.html { render :action => "edit" }
        format.json { render :json => @use_license.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @use_license.destroy

    respond_to do |format|
      format.html { redirect_to(use_licenses_url) }
      format.json { head :no_content }
    end
  end
end


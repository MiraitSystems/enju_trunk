class UseLicensesController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.use_license'))", 'use_licenses_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.use_license'))", 'use_license_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.use_license'))", 'new_use_license_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.use_license'))", 'edit_use_license_path(params[:id])', :only => [:edit, :update]

  respond_to :html, :json
  before_filter :check_client_ip_address
  load_and_authorize_resource

  # セレクターの設定
  before_filter :set_selector

  def set_selector
    @author_fees = [[t('flag.yes'), true], [t('flag.no'), false]]
    @account_kinds = [[t('activerecord.attributes.use_license.account_kinds.normal'), 1],
                      [t('activerecord.attributes.use_license.account_kinds.current'), 2]]
  end

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


class CurrenciesController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.currency'))", 'currencies_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.currency'))", 'currency_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.currency'))", 'new_currency_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.currency'))", 'edit_currency_path(params[:id])', :only => [:edit, :update]

  before_filter :check_client_ip_address
  load_and_authorize_resource

  def index
    @currencies = Currency.page(params[:page])
  end

  def new
    @currency = Currency.new
  end

  def create
    @currency = Currency.new(params[:currency])

    respond_to do |format|
      if @currency.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.currency'))
        format.html { redirect_to :action => "index" }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @currency = Currency.find(params[:id])
  end

  def update
    @currency = Currency.find(params[:id])

    respond_to do |format|
      if @currency.update_attributes(params[:currency])
         flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.currency'))
        format.html { redirect_to :action => "index" }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @currency = Currency.find(params[:id])
  end

  def destroy
    @currency = Currency.find(params[:id])
    respond_to do |format|
      if @currency.destroy?
        @currency.destroy
        format.html { redirect_to(currencies_url) }
      else
        flash[:message] = t('currency.cannot_delete')
        @terms = Currency.all
        format.html { redirect_to(currencies_url) }
      end
    end
  end

end

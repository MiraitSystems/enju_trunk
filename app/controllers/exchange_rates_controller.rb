# -*- encoding: utf-8 -*-
class ExchangeRatesController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.exchange_rate'))", 'exchange_rates_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.exchange_rate'))", 'exchange_rate_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.exchange_rate'))", 'new_exchange_rate_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.exchange_rate'))", 'edit_exchange_rate_path(params[:id])', :only => [:edit, :update]

  before_filter :check_client_ip_address
  load_and_authorize_resource
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  def index

    @count = {}
    page = params[:page] || 1
    per_page = params[:format] == 'tsv' ? 65534 : ExchangeRate.default_per_page
    query = params[:query].to_s.strip

    order_list = @order_list
    search = ExchangeRate.search.build do
      fulltext query if query
      order_by(:started_at, :desc)
      paginate :page => page.to_i, :per_page => per_page
    end.execute
    @exchange_rates = search.results
    @currencies = Currency.find(:all, :order => "display_name DESC")

    # 発注への通貨レート反映処理
    begin
      start_at = params[:orders_started_at]
      end_at = params[:orders_ended_at]
      update_to_orders = params[:update_to_orders]

      if update_to_orders
        ExchangeRate.check_order_date(start_at, end_at)
        orders = Order.where(:ordered_at => start_at...end_at)
        orders.each do |order|
          newest_rate = ExchangeRate.find(:first, :conditions => { :currency_id => (order.currency_id) }, :order => "started_at DESC")
          order.currency_rate = newest_rate.rate
          order.save
        end
        flash[:orders_notice] = t('controller.successfully_updated', :model => t('activerecord.models.order'))
        redirect_to :action => "index"
      end
    rescue => e
        flash[:orders_error] = e.message
        redirect_to :action => "index"
    end 
  end

  def new
    @exchange_rate = ExchangeRate.new
    @currencies = Currency.find(:all, :order => "display_name")

  end

  def create

    @exchange_rate = ExchangeRate.new(params[:exchange_rate])

    respond_to do |format|
      if @exchange_rate.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.exchange_rate'))
        format.html { redirect_to :action => "index" }
      else
        @currencies = Currency.find(:all, :order => "name")
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @exchange_rate = ExchangeRate.find(params[:id])
    @exchange_rate.started_at = @exchange_rate.started_at.to_date
    @currencies = Currency.find(:all, :order => "display_name")
  end

  def update
    @exchange_rate = ExchangeRate.find(params[:id])

    respond_to do |format|
      if @exchange_rate.update_attributes(params[:exchange_rate])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.exchange_rate'))       
        format.html { redirect_to :action => "index" }
      else
        @currencies = Currency.find(:all, :order => "name")
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @exchange_rate = ExchangeRate.find(params[:id])
  end

  def destroy
    @exchange_rate = ExchangeRate.find(params[:id])
    respond_to do |format|
        @exchange_rate.destroy
        format.html { redirect_to(exchange_rates_url) }
    end
  end

end

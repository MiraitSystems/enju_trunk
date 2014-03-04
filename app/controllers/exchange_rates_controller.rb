# -*- encoding: utf-8 -*-
class ExchangeRatesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource

  def index
=begin
    @count = {}
    case params[:sort_by]
    when 'updated_at'
      sort_by = 'updated_at'
    when 'created_at'
      sort_by = 'created_at'
    when 'answers_count'
      sort_by = 'answers_count'
    else
      sort_by = 'updated_at'
    end

    search = Sunspot.new_search(ExchangeRate)
    query = params[:query].to_s.strip
    unless query.blank?
      @query = query.dup
      query = query.gsub('　', ' ')
      search.build do
        fulltext query
      end
    end
    search.build do
      order_by sort_by, :desc
    end
=end
    if params[:currency] != nil && params[:currency][:display_name] != ''
      @exchange_rates = ExchangeRate.where(["currency_id = ?",params[:currency][:display_name]]).order("started_at desc").page(params[:page])
      @currencies_selected = params[:currency][:display_name]
    else
      @exchange_rates = ExchangeRate.order("started_at desc").page(params[:page])
    end	

    @currencies = Currency.find(:all, :order => "display_name")

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

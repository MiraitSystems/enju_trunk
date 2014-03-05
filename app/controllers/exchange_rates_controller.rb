# -*- encoding: utf-8 -*-
class ExchangeRatesController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource
  after_filter :solr_commit, :only => [:create, :update, :destroy]

  def index
    # TODO if 検索語を入力した時の処理

    @count = {}
    page = params[:page] || 1
    per_page = params[:format] == 'tsv' ? 65534 : ExchangeRate.default_per_page
    query = params[:query].to_s.strip

    order_list = @order_list
    search = ExchangeRate.search.build do
      fulltext query if query
      order_by(:started_at, :desc)
      # facet (:currency_id)
      paginate :page => page.to_i, :per_page => per_page
    end.execute
    # @newest_rates_facet = search.facet(:currency_id).rows
    @exchange_rates = search.results

    # TODO
    @currencies = Currency.find(:all, :order => "display_name DESC")
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

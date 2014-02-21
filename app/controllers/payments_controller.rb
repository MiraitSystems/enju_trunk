class PaymentsController < ApplicationController
  load_and_authorize_resource
  before_filter :get_order

  def index
    if params[:order_id]
      @payments = Payment.where(["order_id = ?",params[:order_id]]).page(params[:page])
      @order = Order.find(params[:order_id])
    else
      @payments = Payment.page(params[:page])
      set_select_years
    end
  end

  def new
    @payment = Payment.new
    @payment.auto_calculation_flag = 1
    @payment.billing_date = Date.today

    if params[:order_id]
      @order = Order.find(params[:order_id])
      @payment.manifestation_id = @order.manifestation_id
      @payment.order_id = @order.id 
    end
  end

  def create
    @payment = Payment.new(params[:payment])

    respond_to do |format|
      if @payment.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.payment'))
        format.html { redirect_to @payment }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @payment = Payment.find(params[:id])
  end

  def update
    @payment = Payment.find(params[:id])

    respond_to do |format|
      if @payment.update_attributes(params[:payment])
         flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.payment'))
        format.html { redirect_to(@payment) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @payment = Payment.find(params[:id])
  end

  def destroy
    @payment = Payment.find(params[:id])
    respond_to do |format|
        @payment.destroy
        format.html { redirect_to(payments_url) }
    end
  end


  def search
    
    unless params[:manifestation_original_title].blank?
      manifestation_num = Manifestation.where("original_title ILIKE ?", "\%#{params[:manifestation_original_title]}\%")
      flash.now[:message] = t('payment.no_matches_found_manifestation', :attribute => t('activerecord.attributes.manifestation.original_title')) if manifestation_num.size == 0
    end

    unless params[:manifestation_identifier].blank?
      manifestation_num = Manifestation.where("identifier = ?", params[:manifestation_identifier])

      flash.now[:message] = t('payment.no_matches_found_manifestation', :attribute => t('activerecord.attributes.manifestation.identifier')) if manifestation_num.size == 0
    end

    unless params[:order_identifier].blank?
      order_num = Order.where("order_identifier = ?", params[:order_identifier])
      flash.now[:message] = t('payment.no_matches_found_order', :attribute => t('activerecord.attributes.order.order_identifier')) if order_num.size == 0
    end


    where_str = ""
    where_str += "original_title ILIKE ?" 

    unless params[:order_identifier].blank?
      where_str += " AND order_identifier = '#{params[:order_identifier]}'"
    end

    unless params[:publication_year].blank?
      where_str += " AND publication_year = #{params[:publication_year].to_i}"
    end

    unless params[:manifestation_identifier].blank?
      where_str += " AND identifier = '#{params[:manifestation_identifier]}'"
    end


    @payments = Payment.joins(:order,:manifestation).where([where_str, "\%#{params[:manifestation_original_title]}\%"]).page(params[:page])

    @selected_order_identifier = params[:order_identifier]
    @selected_manifestation = params[:manifestation_identifier]
    @selected_year = params[:publication_year]
    @selected_title = params[:manifestation_original_title]

    set_select_years

    respond_to do |format|
      format.html {render "index"}
    end

  end

  def set_select_years
    @years = Order.select(:publication_year).uniq.order('publication_year desc')
    @select_years = []
    @years.each do |p|
      @select_years.push [p.publication_year, p.publication_year] unless p.publication_year.blank?
    end

  end


private
  def get_order
    @order = Order.find(params[:order_id]) if params[:order_id]
  end
end

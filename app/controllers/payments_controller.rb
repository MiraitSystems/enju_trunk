class PaymentsController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.payment'))", 'payments_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.payment'))", 'payment_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.payment'))", 'new_payment_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.payment'))", 'edit_payment_path(params[:id])', :only => [:edit, :update]

  load_and_authorize_resource
  before_filter :get_order


  def index
    if params[:order_id]
      @payments = Payment.where(["order_id = ?",params[:order_id]]).order("id DESC").page(params[:page])
      @order = Order.find(params[:order_id])
    else
      @payments = Payment.order("id DESC").page(params[:page])
    end
      set_select_years
  end

  def new
    @payment = Payment.new
    @payment.billing_date = Date.today
    @return_index = params[:return_index]

    if params[:order_id]
      @order = Order.find(params[:order_id])
      @payment.manifestation_id = @order.manifestation_id
      @payment.order_id = @order.id 
    end
  end

  def create
    @payment = Payment.new(params[:payment])
    @auto_calculation_flag = params[:payment_auto_calculation][:flag] == '1' ? true : false
    @return_index = params[:return_index]

    respond_to do |format|
      if @payment.save
        @payment.set_amount_of_payment if params[:payment_auto_calculation][:flag] == '1'
        @payment.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.payment'))
        format.html { redirect_to (payment_path(@payment, :return_index => @return_index)) }
      else
        format.html { render :action => "new" }
      end
    end
  end

  def edit
    @payment = Payment.find(params[:id])
    @return_index = params[:return_index]
  end

  def update
    @payment = Payment.find(params[:id])
    @return_index = params[:return_index]

    @auto_calculation_flag = params[:payment_auto_calculation][:flag] == '1' ? true : false
    @return_index = params[:return_index]

    respond_to do |format|
      if @payment.update_attributes(params[:payment])
        @payment.set_amount_of_payment if params[:payment_auto_calculation][:flag] == '1'
        @payment.save
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.payment'))
        format.html { redirect_to(payment_path(@payment, :return_index => @return_index)) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def show
    @payment = Payment.find(params[:id])
    @return_index = params[:return_index]
  end

  def destroy
    @payment = Payment.find(params[:id])
    order = @payment.order
    respond_to do |format|
        @payment.destroy
        format.html {
          if params[:return_index]
            redirect_to(order_payments_url(order)) 
          else
            redirect_to(payments_url) 
          end
        }
    end
  end

  def set_select_years
    @years = Order.select(:order_year).uniq.order('order_year desc')
    @select_years = []
    @years.each do |p|
      @select_years.push [p.order_year, p.order_year] unless p.order_year.blank?
    end

  end

  def search
    
    unless params[:order_identifier].blank?
      order = Order.find_by_order_identifier(params[:order_identifier])

      if order
        @manifestation_original_title = order.manifestation.original_title
      else
        flash.now[:message] = t('payment.no_matches_found_order', :attribute => t('activerecord.attributes.order.order_identifier')) 
      end

    end


    where_str = ""
    unless params[:order_identifier].blank?
      where_str += "order_identifier = '#{params[:order_identifier]}'"
    end

    unless params[:order_year].blank?
      where_str += " AND " unless where_str.empty?
      where_str += "order_year = #{params[:order_year].to_i}"
    end


    if where_str.empty?
      @payments = Payment.page(params[:page])
    else
      @payments = Payment.joins(:order,:manifestation).where([where_str]).order("id DESC").page(params[:page])
    end


    @selected_order_identifier = params[:order_identifier]
    @selected_year = params[:order_year]

    set_select_years

    respond_to do |format|
      format.html {render "index"}
    end

  end

  def set_select_years
    @years = Order.select(:order_year).uniq.order('order_year desc')
    @select_years = []
    @years.each do |p|
      @select_years.push [p.order_year, p.order_year] unless p.order_year.blank?
    end

  end

private
  def get_order
    @order = Order.find(params[:order_id]) if params[:order_id]
  end
end

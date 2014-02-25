class PaymentsController < ApplicationController
  load_and_authorize_resource
  before_filter :get_order


  def index
    if params[:order_id]
      @payments = Payment.where(["order_id = ?",params[:order_id]]).page(params[:page])
      @order = Order.find(params[:order_id])
    else
      @payments = Payment.page(params[:page])
    end
      set_select_years
  end

  def new
    @payment = Payment.new
    @payment.auto_calculation_flag = 1
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
    @return_index = params[:return_index]

    respond_to do |format|
      if @payment.save
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

    respond_to do |format|
      if @payment.update_attributes(params[:payment])
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

    unless params[:publication_year].blank?
      where_str += " AND " unless where_str.empty?
      where_str += "publication_year = #{params[:publication_year].to_i}"
    end


    if where_str.empty?
      @payments = Payment.page(params[:page])
    else
      @payments = Payment.joins(:order,:manifestation).where([where_str]).page(params[:page])
    end


    @selected_order_identifier = params[:order_identifier]
    @selected_year = params[:publication_year]

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

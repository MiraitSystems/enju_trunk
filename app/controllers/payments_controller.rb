class PaymentsController < ApplicationController

  load_and_authorize_resource

  def index
    if params[:order_id]
      @payments = Payment.where(["order_id = ?",params[:order_id]]).page(params[:page])
      @order = Order.find(params[:order_id])
    else
      @payments = Payment.page(params[:page])
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
    unless params[:manifestation_identifier].blank?
      manifestation_num = Manifestation.where("identifier = ?", params[:manifestation_identifier])
      flash.now[:message] = t('payment.no_matches_found_manifestation') if manifestation_num.size == 0
    end

    unless params[:order_identifier].blank?
      order_num = Order.where("order_identifier = ?", params[:order_identifier])
      flash.now[:message] = t('payment.no_matches_found_order') if order_num.size == 0
    end

    unless params[:order_identifier].blank?

      unless params[:manifestation_identifier].blank?
        @payments = Payment.joins(:order, :manifestation).where("order_identifier = ? AND identifier = ?", params[:order_identifier], params[:manifestation_identifier]).page(params[:page])
      else
        @payments = Payment.joins(:order).where("order_identifier = ?", params[:order_identifier]).page(params[:page])
      end
    else
      unless params[:manifestation_identifier].blank?
        @payments = Payment.joins(:manifestation).where("identifier = ?", params[:manifestation_identifier]).page(params[:page])
      else
        @payments = Payment.page(params[:page])
      end
    end

    @order_identifier_selected = params[:order_identifier]
    @manifestation_selected = params[:manifestation_identifier]


    respond_to do |format|
      format.html {render "index"}
    end

  end


end

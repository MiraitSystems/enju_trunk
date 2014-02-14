class PaymentsController < ApplicationController

  load_and_authorize_resource

  def index
    @payments = Payment.page(params[:page])

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

end

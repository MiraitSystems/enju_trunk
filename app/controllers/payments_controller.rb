class PaymentsController < ApplicationController


  def index
    @payments = Payment.page(params[:page])
  end

  def new
    @payment = Payment.new

    # test s
    @payment.manifestation_id = 1
    @payment.order_id = 1
    # test e
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
      if @payment.destroy?
        @payment.destroy
        format.html { redirect_to(payments_url) }
      else
        flash[:message] = t('payment.cannot_delete')
        @terms = Payment.all
        format.html { redirect_to(payments_url) }
      end
    end
  end


end

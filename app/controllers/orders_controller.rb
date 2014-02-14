class OrdersController < ApplicationController
  #before_filter :check_client_ip_address
  #authorize_function

  load_and_authorize_resource

  # GET /orders
  # GET /orders.json
  def index
      @orders = Order.page(params[:page])

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @orders }
      format.rss
      format.atom
      format.csv
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = Order.find(params[:id])
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
    @order = Order.new
    @order.auto_calculation_flag = 1
    @order.order_identifier = Numbering.do_numbering('order')
    @order.order_day = Date.today

    @select_patron_tags = Order.struct_patron_selects
    @currencies = Currency.all

      if params[:manifestation_id]
        @order.manifestation_id = params[:manifestation_id].to_i
        @order.manifestation = Manifestation.find(params[:manifestation_id].to_i)
      end 
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
    @select_patron_tags = Order.struct_patron_selects
    @currencies = Currency.all
  end

  # POST /orders
  # POST /orders.json
  def create

    @order = Order.new(params[:order])
    @manifestation_identifier = params[:manifestation_identifier]
    manifestation = Manifestation.find_by_identifier(@manifestation_identifier) unless @manifestation_identifier.blank?
    @order.manifestation_id = manifestation.id if manifestation
 
    respond_to do |format|
      if @order.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.order'))
        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.json { render :json => @order, :status => :created, :location => @order }
        else
          format.html { redirect_to(@order) }
          format.json { render :json => @order, :status => :created, :location => @order }
        end
      else

        @select_patron_tags = Order.struct_patron_selects
        @currencies = Currency.all
        @order_lists = OrderList.not_ordered
        format.html { render :action => "new" }
        format.json { render :json => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(params[:order])
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.order'))
        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.json { head :no_content }
        else
          format.html { redirect_to(@order) }
          format.json { head :no_content }
        end
      else
          @select_patron_tags = Order.struct_patron_selects
          @currencies = Currency.all
        @order_lists = OrderList.not_ordered
        format.html { render :action => "edit" }
        format.json { render :json => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.destroy?
        @order.destroy
        format.html {redirect_to(orders_url)}
      else
        flash[:message] = t('order.cannot_delete')
        format.html {redirect_to(orders_url)}
      end
    end
  end

  def paid

    @order = Order.find(params[:order_id])
    @flag =  self.class.helpers.get_paid_flag
    @order.paid_flag = @flag.id if @flag
    @order.save
    Payment.create_paid(params[:order_id])

    respond_to do |format|
      flash[:notice] = t('controller.successfully_created', :model => t('payment.paid'))
      format.html {redirect_to(@order)}
    end
  end

end

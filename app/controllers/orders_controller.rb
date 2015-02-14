class OrdersController < ApplicationController
  before_filter :get_order_list
  before_filter :get_purchase_request

  load_and_authorize_resource

  # GET /orders
  # GET /orders.json
  def index
    case
    when @order_list
      @orders = @order_list.orders.page(params[:page])
    else
      @orders = Order.page(params[:page])
    end
    @count = {}
    @count[:query_result] = @orders.size

    respond_to do |format|
      format.html # index.html.erb
      format.json { render json: @orders }
    end
  end

  # GET /orders/1
  # GET /orders/1.json
  def show
    @order = Order.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/new
  # GET /orders/new.json
  def new
    @order_lists = OrderList.not_ordered
    @item = Item.find(params[:item_id])
    @order = Order.new(item_id: params[:item_id])
    @order.price_string_on_order = @item.price

    respond_to do |format|
      format.html # new.html.erb
      format.json { render json: @order }
    end
  end

  # GET /orders/1/edit
  def edit
    @order = Order.find(params[:id])
    @order_lists = OrderList.not_ordered
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(params[:order])
    if @order.item_id.blank? && @order.manifestion_id.blank?
      # error
    end

    if @order.item_id.present?
      @item = Item.find(@order.item_id)
    elsif @order.manifestation_id.present?
      @manifestation = Item.find(@manifestation.item_id)
    end

    respond_to do |format|
      if @order.save
        flash[:notice] = t('controller.successfully_created', model: t('activerecord.models.order'))
        format.html { redirect_to(@order) }
        format.json { render json: @order, status: :created, location: @order }
      else
        @order_lists = OrderList.not_ordered
        format.html { render action: "new" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # PUT /orders/1
  # PUT /orders/1.json
  def update
    @order = Order.find(params[:id])

    respond_to do |format|
      if @order.update_attributes(order_params)
        flash[:notice] = t('controller.successfully_updated', model: t('activerecord.models.order'))
        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.json { head :no_content }
        else
          format.html { redirect_to(@order) }
          format.json { head :no_content }
        end
      else
        @order_lists = OrderList.not_ordered
        format.html { render action: "edit" }
        format.json { render json: @order.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = Order.find(params[:id])

    @order.destroy

    respond_to do |format|
      if @order_list
        format.html { redirect_to purchase_requests_url(order_list: @order_list.id) }
        format.json { head :no_content }
      else
        format.html { redirect_to orders_url }
        format.json { head :no_content }
      end
    end
  end

end

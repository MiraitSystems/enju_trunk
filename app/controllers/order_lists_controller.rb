class OrderListsController < ApplicationController
  before_filter :check_client_ip_address
  load_and_authorize_resource
  before_filter :get_bookstore
  unless SystemConfiguration.get("use_order_lists")
    before_filter :access_denied
  end

  # GET /order_lists
  # GET /order_lists.json
  def index
    if @bookstore
      @order_lists = @bookstore.order_lists.page(params[:page])
    else
      @order_lists = OrderList.page(params[:page])
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @order_lists }
      format.rss  { render :layout => false }
      format.atom
    end
  end

  # GET /order_lists/1
  # GET /order_lists/1.json
  def show
    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @order_list }
    end
  end

  # GET /order_lists/new
  # GET /order_lists/new.json
  def new
    @order_list = OrderList.new
    @bookstores = Bookstore.all

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @order_list }
    end
  end

  # GET /order_lists/1/edit
  def edit
    @bookstores = Bookstore.all
  end

  # POST /order_lists
  # POST /order_lists.json
  def create
    @order_list = OrderList.new(params[:order_list])
    @order_list.user = current_user

    respond_to do |format|
      if @order_list.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.order_list'))
        format.html { redirect_to(@order_list) }
        format.json { render :json => @order_list, :status => :created, :location => @order_list }
      else
        @bookstores = Bookstore.all
        format.html { render :action => "new" }
        format.json { render :json => @order_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /order_lists/1
  # PUT /order_lists/1.json
  def update
    respond_to do |format|
      if @order_list.update_attributes(params[:order_list])
        @order_list.sm_order! if params[:mode] == 'order'
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.order_list'))
        format.html { redirect_to(@order_list) }
        format.json { head :no_content }
      else
        @bookstores = Bookstore.all
        format.html { render :action => "edit" }
        format.json { render :json => @order_list.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /order_lists/1
  # DELETE /order_lists/1.json
  def destroy
    @order_list.destroy

    respond_to do |format|
      format.html { redirect_to(order_lists_url) }
      format.json { head :no_content }
    end
  end

  def do_order
    @order_list.do_order
    redirect_to @order_list, flash: {success: t('order_list.order_list_success')}
  end

  def order_letter
    filename = @order_list.order_letter_filename
    logger.info "order_letter filename=#{filename}"
    send_file filename, :filename => "発注票.tsv".encode("cp932"), :type => 'application/octet-stream'

  end

  def manage_list_of_order
    @start_at_s = params[:start_at]
    @end_at_s = params[:end_at]
    action = params[:submit_order_list] || params[:submit_not_arrival_list]

    if @start_at_s.blank? || @end_at_s.blank? || action.blank?
      logger.debug "blank parameter"
      flash[:alert] = t('order_list.error_msg')
      render :action => "manage"
      return
    end

    start_at = end_at = nil
    begin
      start_at = DateTime.parse(@start_at_s)
      end_at = DateTime.parse(@end_at_s)
    rescue => e
      # error
      logger.debug "invalid format (1)"
      logger.debug e.message
      logger.debug e.backtrace.first
    end

    if start_at.blank? || end_at.blank?
      logger.debug "invalid date"
      flash[:alert] = t('order_list.error_msg_invalid')
      render :action => "manage"
      return
    end

    if params[:submit_order_list]
      filename = OrderList.generate_order_list(start_at, end_at)
      logger.info "order_list filename=#{filename}"
      send_file filename, :filename => "order_list.tsv".encode("cp932"), :type => 'application/octet-stream'
    elsif params[:submit_not_arrival_list]
      logger.info "submit_order_list"

    end

  end
end

class OrdersController < ApplicationController
  add_breadcrumb "I18n.t('page.listing', :model => I18n.t('activerecord.models.order'))", 'orders_path', :only => [:index]
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.order'))", 'order_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.order'))", 'new_order_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.order'))", 'edit_order_path(params[:id])', :only => [:edit, :update]

  #before_filter :check_client_ip_address
  #authorize_function
  load_and_authorize_resource
  before_filter :get_manifestation

  def initialize
    @selected_bookstore_code, @selected_payment_form_code, @selected_order_organization_id = [], [], []
    @agents = Agent.joins(:agent_type).where(["agent_types.name = 'OrderOrganization'"]).order(:id)
    @ouput_columns = Order.ouput_columns
    @document_application_columns = Order.document_application_columns
    @list_of_order_columns = Order.list_of_order_columns
    @list_of_deferred_payment_acceptance_columns = Order.list_of_deferred_payment_acceptance_columns
    @list_of_acceptance_situation_columns = Order.list_of_acceptance_situation_columns
    @list_of_payment_columns = Order.list_of_payment_columns
    @list_of_acceptance_after_payment_columns = Order.list_of_acceptance_after_payment_columns
    super
  end

  # POST /orders/output_csv
  def output_csv
    orders = Order.scoped
    unless params[:order_identifier].blank?
      orders = orders.where(["order_identifier like ?", params[:order_identifier] + "%"])
    end
    unless params[:publication_year].blank?
      orders = orders.where(["publication_year = ?", params[:publication_year]])
    end
    unless params[:identifier].blank?
      orders = orders.where(["manifestations.identifier like ?", params[:identifier] + "%"])
    end
    params[:bookstore_code].delete("")
    unless params[:bookstore_code].blank?
      if params[:bookstore_code].include?("notset")
        ids = params[:bookstore_code].reject{|e| e == "notset"}
        if ids.blank?
          orders = orders.where("bookstore_code IS NULL")
        else
          orders = orders.where(["bookstore_code in (?) OR bookstore_code IS NULL", ids])
        end
      else
        orders = orders.where(["bookstore_code in (?)", params[:bookstore_code]])
      end
    end
    params[:order_organization_id].delete("")
    unless params[:order_organization_id].blank?
      if params[:order_organization_id].include?("notset")
        ids = params[:order_organization_id].reject{|e| e == "notset"}
        if ids.blank?
          orders = orders.where("order_organization_id IS NULL")
        else
          orders = orders.where(["order_organization_id in (?) OR order_organization_id IS NULL", ids])
        end
      else
        orders = orders.where(["order_organization_id in (?)", params[:order_organization_id]])
      end
    end
    params[:payment_form_code].delete("")
    unless params[:payment_form_code].blank?
      if params[:payment_form_code].include?("notset")
        ids = params[:payment_form_code].reject{|e| e == "notset"}
        if ids.blank?
          orders = orders.where("payment_form_code IS NULL")
        else
          orders = orders.where(["payment_form_code in (?) OR payment_form_code IS NULL", ids])
        end
      else
        orders = orders.where(["payment_form_code in (?)", params[:payment_form_code]])
      end
    end

    orders = orders.order("bookstore_code, order_organization_id, manifestations.identifier")
    orders = orders.includes(:manifestation, :agent)
    
    data = CSV.generate(:force_quotes => true) do |csv|
      if params[:ouput_column].present?
        header = []
        params[:ouput_column].each do |name|
          name_ja = t("order_output_csv.#{name}")
          header << name_ja
        end
        csv << header
        orders.each.with_index(1) do |order, index|
          detail = []
          params[:ouput_column].each do |name|
          ouput_column = @ouput_columns.find{|ouput_column| ouput_column[:name] == name }
          model = ouput_column[:model]
          column = ouput_column[:column]
          case model
            when "orders"
              case column
                when "bookstore_code"
                  detail << (order.bookstore.present? ? order.bookstore.keyname : "")
                when "collection_status_code"
                  detail << (order.collection_status.present? ? order.collection_status.keyname : "")
                when "currency_id"
                  detail << (order.currency.present? ? order.currency.display_name : "")
                when "payment_form_code"
                  detail << (order.payment_form.present? ? order.payment_form.keyname : "")
                when "transportation_route_code"
                  detail << (order.transportation_route.present? ? order.transportation_route.keyname : "")
                when "order_organization_id"
                  detail << (order.agent.present? ? order.agent.full_name : "")
                else
                  detail << order[column]
              end
            when "manifestations"
              case column
                when "country_of_publication_id"
                  detail << (order.manifestation.country_of_publication.present? ? order.manifestation.country_of_publication.display_name : "")
                when "frequency_id"
                  detail << (order.manifestation.frequency.present? ? order.manifestation.frequency.display_name : "")
                when "publishers"
                  if order.manifestation.publishers.present?
                    publisher_names = order.manifestation.publishers.pluck(:full_name)
                    detail << publisher_names.join(" ")
                  else
                    detail << ""
                  end
                when "issue_number_string"
                  case name
                    when "issue_number_string"
                      if order.manifestation.manifestation_type.name == "serial"
                        detail << order.manifestation.issue_number_string
                      else
                        detail << ""
                      end
                    when "report_number_string"
                      if order.manifestation.manifestation_type.name == "analitical"
                        detail << order.manifestation.issue_number_string
                      else
                        detail << ""
                      end
                  end
                when "volume_number_string"
                  case name
                    when "volume_number_string"
                      if order.manifestation.manifestation_type.name == "serial"
                        detail << order.manifestation.volume_number_string
                      else
                        detail << ""
                      end
                    when "report_volume_number_string"
                      if order.manifestation.manifestation_type.name == "analitical"
                        detail << order.manifestation.volume_number_string
                      else
                        detail << ""
                      end
                  end
                else
                  detail << order.manifestation[column]
                end
              when "agents"
                if order.agent.present?
                  detail << order.agent[column]
                else
                  detail << ""
                end
              when "items"
                if order.manifestation.items.present?
                  detail << order.manifestation.items.first[column]
                else
                  detail << ""
                end
              else
                case name
                  when "number"
                    detail << index
                  when "prepayment_principal_rate"
                    detail << (order.original_price * order.currency_rate).to_i
                  when "quantity"
                    detail << 1
                  when "deduction_quantity"
                    detail << (order.number_of_acceptance_schedule - order.number_of_acceptance)
                  when "delayed_quantity"
                    detail << (order.number_of_acceptance_schedule - (order.number_of_acceptance - order.number_of_missing))
                  else
                    detail << nil
                end
            end
          end
          csv << detail
        end
      end
    end
    data = data.encode(Encoding::SJIS)
    send_data(data, type: 'text/csv', filename: "orders_list_#{Time.now.strftime('%Y_%m_%d_%H_%M_%S')}.csv")
  end

  # GET /orders
  # GET /orders.json
  def index
    if params[:manifestation_id]
      @orders = Order.where(["manifestation_id = ?",params[:manifestation_id]]).order("order_year DESC, order_identifier DESC").page(params[:page])
      @manifestation = Manifestation.find(params[:manifestation_id])
    else
      # all checked
      @check_all_bookstore_code = true
      @check_all_order_organization_id = true
      @check_all_payment_form_code = true
      @selected_year = Time.now.year
      bookstore_codes = self.class.helpers.bookstore_codes
      @selected_bookstore_code = bookstore_codes.present? ? bookstore_codes.pluck(:id).collect{|i| i.to_s} : []
      @selected_bookstore_code << "notset"
      payment_form_codes = self.class.helpers.payment_form_codes
      @selected_payment_form_code = payment_form_codes.present? ? payment_form_codes.pluck(:id).collect{|i| i.to_s} : []
      @selected_payment_form_code << "notset"
      @selected_order_organization_id = @agents.present? ? agents.pluck(:id).collect{|i| i.to_s} : []
      @selected_order_organization_id << "notset"
      @orders = Order.where(["order_year = ?",@selected_year]).order("order_identifier DESC").page(params[:page])
    end

    set_select_years

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

    @return_index = params[:return_index]

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
    original_order = Order.where(:id => params[:order_id]).first
    if original_order
      @order = original_order.dup
      @order.order_identifier = Order.set_order_identifier
      @order.ordered_at = Date.new(original_order.ordered_at.year, original_order.ordered_at.month, original_order.ordered_at.day)
      @order.order_year = original_order.order_year
      @order.paid_flag = 0
      @order.buying_payment_year = nil
      @order.prepayment_settlements_of_account_year = nil
    else
      @order.ordered_at = Date.today
      @order.order_identifier = Order.set_order_identifier
      if params[:manifestation_id]
        @order.manifestation_id = params[:manifestation_id].to_i
      end 
    end

    @select_agent_tags = Order.struct_agent_selects
    @currencies = Currency.all
    @return_index = params[:return_index]

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
    @select_agent_tags = Order.struct_agent_selects
    @currencies = Currency.all
    @return_index = params[:return_index]
  end

  # POST /orders
  # POST /orders.json
  def create
    @order = Order.new(params[:order])
    @auto_calculation_flag = params[:order_auto_calculation][:flag] == '1' ? true : false
    @return_index = params[:return_index]
    respond_to do |format|
      if @order.save
        @order.set_cost if params[:order_auto_calculation][:flag] == '1'
        @order.save
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.order'))
        flash[:notice] += t('order.create_payment_to_advance_payment') if @order.create_payment_to_advance_payment

        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.json { render :json => @order, :status => :created, :location => @order }
        else
          format.html { redirect_to(order_path(@order, :return_index => @return_index)) }
          format.json { render :json => @order, :status => :created, :location => @order }
        end
      else

        @select_agent_tags = Order.struct_agent_selects
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
    @auto_calculation_flag = params[:order_auto_calculation][:flag] == '1' ? true : false

    respond_to do |format|
      if @order.update_attributes(params[:order])
        @order.set_cost if params[:order_auto_calculation][:flag] == '1'
        @order.save
        flash[:notice] = t('controller.successfully_updated', :model => t('activerecord.models.order'))

        if @purchase_request
          format.html { redirect_to purchase_request_order_url(@order.purchase_request, @order) }
          format.json { head :no_content }
        else
          format.html { redirect_to( order_path(@order, :return_index => params[:return_index])) }
          format.json { head :no_content }
        end
      else
          @select_agent_tags = Order.struct_agent_selects
          @currencies = Currency.all
          @return_index = params[:return_index] if params[:return_index]
          #@order_lists = OrderList.not_ordered
         
        format.html { render :action => "edit" }
        format.json { render :json => @order.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /orders/1
  # DELETE /orders/1.json
  def destroy
    @order = Order.find(params[:id])
    manifestation = @order.manifestation

    respond_to do |format|
      if @order.destroy?
        @order.destroy
        format.html {
          if params[:return_index]
            redirect_to(manifestation_orders_url(manifestation))
          else
            redirect_to(orders_url)
          end
        }
      else
        flash[:message] = t('order.cannot_delete')
        format.html {
          if params[:return_index]
            redirect_to(manifestation_orders_url(manifestation))
          else
            redirect_to(orders_url)
          end
        }
      end
    end
  end

  def paid
    notice = nil
    begin
      Order.transaction do
        @flag = self.class.helpers.get_paid_flag
        @order.paid_flag = @flag.id if @flag
        @order.save
        Payment.create_paid(@order)
      end
      notice = t('controller.successfully_created', :model => t('payment.paid'))
    rescue => e
      notice = e.message
    end
    respond_to do |format|
      flash[:notice] = notice
      format.html { redirect_to order_path(@order, :return_index => params[:return_index]) }
    end
  end

  def search

    @orders = Order.scoped
    
    unless params[:order_identifier].blank?
      @orders = @orders.where(["order_identifier like ?", params[:order_identifier] + "%"])
      order = Order.where(["order_identifier like ?", params[:order_identifier] + "%"]).first

      flash.now[:message] = t('order.no_matches_found_order', :attribute => t('activerecord.attributes.order.order_identifier')) unless order
    end

    unless params[:order_year].blank?
      @orders = @orders.where(["order_year = ?", params[:order_year]])
    end

    # identifier
    unless params[:identifier].blank?
      @orders = @orders.where(["manifestations.identifier like ?", params[:identifier] + "%"])
    end

    # bookstore_code
    unless params[:bookstore_code].blank?
      if params[:bookstore_code].include?("notset")
        ids = params[:bookstore_code].reject{|e| e == "notset"}
        if ids.blank?
          @orders = @orders.where("bookstore_code IS NULL")
        else
          @orders = @orders.where(["bookstore_code in (?) OR bookstore_code IS NULL", ids])
        end
      else
        @orders = @orders.where(["bookstore_code in (?)", params[:bookstore_code]])
      end
    end

    # order_organization_id
    unless params[:order_organization_id].blank?
      if params[:order_organization_id].include?("notset")
        ids = params[:order_organization_id].reject{|e| e == "notset"}
        if ids.blank?
          @orders = @orders.where("order_organization_id IS NULL")
        else
          @orders = @orders.where(["order_organization_id in (?) OR order_organization_id IS NULL", ids])
        end
      else
        @orders = @orders.where(["order_organization_id in (?)", params[:order_organization_id]])
      end
    end

    # payment_form_code
    unless params[:payment_form_code].blank?
      if params[:payment_form_code].include?("notset")
        ids = params[:payment_form_code].reject{|e| e == "notset"}
        if ids.blank?
          @orders = @orders.where("payment_form_code IS NULL")
        else
          @orders = @orders.where(["payment_form_code in (?) OR payment_form_code IS NULL", ids])
        end
      else
        @orders = @orders.where(["payment_form_code in (?)", params[:payment_form_code]])
      end
    end

    @orders = @orders.order("bookstore_code, order_organization_id, identifier").joins(:manifestation).page(params[:page])
    
    if order
      @selected_title = @orders.first.manifestation.original_title if (@orders.size == 1 && params[:order_identifier].present?)
    end

    @selected_order = params[:order_identifier]
    @selected_year = params[:order_year]
    @selected_identifier = params[:identifier]
    @selected_bookstore_code = params[:bookstore_code] if params[:bookstore_code].present?
    @selected_payment_form_code = params[:payment_form_code] if params[:payment_form_code].present?
    @selected_order_organization_id = params[:order_organization_id] if params[:order_organization_id].present?
    @check_all_bookstore_code = params[:check_all_bookstore_code]
    @check_all_order_organization_id = params[:check_all_order_organization_id]
    @check_all_payment_form_code = params[:check_all_payment_form_code]
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

  def create_subsequent_year_orders

    if params[:order_identifier].blank?
      @orders = Order.where(["order_year = ?", params[:year].to_i])
    else
      @orders = Order.where(["order_year = ? AND order_identifier = ?", params[:year].to_i, params[:order_identifier]])
    end

    create_count = 0
    @orders.each do |order|
      if order.order_form && order.order_form.v == '1'
        @new_order = order.dup
        @new_order.order_identifier = Order.set_order_identifier
        @new_order.ordered_at = Date.new((Date.today + 1.years).year, order.ordered_at.month, order.ordered_at.day)
        @new_order.order_year = Date.today.year.to_i + 1
        @new_order.paid_flag = 0
        @new_order.buying_payment_year = nil
        @new_order.prepayment_settlements_of_account_year = nil
        @new_order.save
        @new_order.create_payment_to_advance_payment
        create_count += 1
      end
    end
 
    if create_count != 0   
      flash[:notice] = t('controller.successfully_created', :model => t('order.subsequent_year_orders'))
    else
      flash[:message] = t('order.no_create_subsequent_year_orders')
    end

    redirect_to :action => "search", :order_year => params[:year], :test => "test", :order_identifier => params[:order_identifier]

  end
  
  def create_ordered_manifestations
    begin
      @order = Order.find(params[:id])
      manifestations = @order.create_manifestations
      if manifestations.size > 0   
        flash[:notice] = t('controller.successfully_created', :model => t('order.items'))
      else
        flash[:notice] = t('order.not_created_items')
      end
      redirect_to order_items_path(@order)
    rescue => ex
      logger.error "Failed to create ordered items: #{ex}"
      flash[:notice] = ex
      redirect_to order_path(@order) 
    end
  end

  def update_order
    begin
      @order = Order.find(params[:id])
      @order.update_order
      flash[:notice] = t('controller.successfully_created', :model => t('order.payments'))
    rescue => ex
      logger.error "Failed to update order: #{ex}"
      flash[:notice] = ex
    end
    redirect_to order_payments_path(@order)
  end

end

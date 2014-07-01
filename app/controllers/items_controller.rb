# -*- encoding: utf-8 -*-
class ItemsController < ApplicationController
  authorize_function
  add_breadcrumb "I18n.t('activerecord.models.item')", 'items_path'
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.item'))", 'new_item_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.editing', :model => I18n.t('activerecord.models.item'))", 'edit_item_path(params[:id])', :only => [:edit, :update]
  include NotificationSound
  load_and_authorize_resource :except => :numbering
  before_filter :get_user
  before_filter :get_agent, :get_manifestation
  helper_method :get_shelf
  helper_method :get_library
  before_filter :get_version, :only => [:show]
  before_filter :check_status, :only => [:edit]
  #before_filter :store_location
  after_filter :solr_commit, :only => [:create, :update, :destroy]
  after_filter :convert_charset, :only => :index

  # GET /items
  # GET /items.json
  def index
    query = params[:query].to_s.strip
    per_page = Item.default_per_page
    @count = {}
    if user_signed_in?
      if current_user.has_role?('Librarian')
        if params[:format] == 'csv'
          per_page = 65534
        elsif params[:mode] == 'barcode'
          per_page = 40
        end
      end
    end

    search = Sunspot.new_search(Item)
    set_role_query(current_user, search)

    @query = query.dup
    unless query.blank?
      search.build do
        fulltext query
      end
    end

    agent = @agent
    manifestation = @manifestation
    shelf = get_shelf
    order = @order = Order.find(params[:order_id]) if params[:order_id]
    unless params[:mode] == 'add'
      search.build do
        with(:agent_ids).equal_to agent.id if agent
        with(:manifestation_id).equal_to manifestation.id if manifestation
        with(:shelf_id).equal_to shelf.id if shelf
        with(:order_id).equal_to order.id if order
      end
    end

    search.build do
      order_by(:created_at, :desc)
    end

    role = current_user.try(:role) || Role.default_role
    search.build do
      with(:required_role_id).less_than role.id
    end

    page = params[:page] || 1
    search.query.paginate(page.to_i, per_page)
    @items = search.execute!.results
    @count[:total] = @items.total_entries

    if params[:mode] == 'barcode'
      render :action => 'barcode', :layout => false
      return
    end

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @items }
      format.csv  { render :layout => false }
      format.atom
    end
  end

  # GET /items/1
  # GET /items/1.json
  def show
    @item = @item.versions.find(@version).item if @version

    # 書誌と所蔵が１：１の場合 manifestations#showにリダイレクト
    if SystemConfiguration.get("manifestation.has_one_item") == true
      redirect_to manifestation_url(@item.manifestation)
      return
    end

    respond_to do |format|
      format.html # show.html.erb
      format.json { render :json => @item }
    end
  end

  # GET /items/new
  def new
    if Shelf.real.blank?
      flash[:notice] = t('item.create_shelf_first')
      redirect_to libraries_url
      return
    end
    unless @manifestation
      flash[:notice] = t('item.specify_manifestation')
      redirect_to manifestations_url
      return
    end
    original_item = Item.where(:id => params[:item_id]).first if params[:item_id]
    if original_item
      @item = original_item.dup
      @item.item_identifier = nil
      @item.rank = 1 if original_item.rank == 0
      @item.use_restriction_id = original_item.use_restriction.id
      @item.library_id = original_item.shelf.library.id
      @item.claim = nil
    else
      @item = Item.new
    end
    @item.manifestation_id = @manifestation.id
    unless @manifestation.article?
      @circulation_statuses = CirculationStatus.order(:position)
      @item.circulation_status = CirculationStatus.where(:name => 'In Process').first unless @item.try(:circulation_status)
      @item.checkout_type = @manifestation.carrier_type.checkout_types.first unless @item.try(:checkout_type)
      @item.use_restriction_id = UseRestriction.where(:name => 'Limited Circulation, Normal Loan Period').select(:id).first.id unless @item.use_restriction_id
      @item.call_number = @manifestation.items.where(:rank => 0).first.call_number unless @item.try(:call_number) rescue nil
      if @item.call_number.blank? && @manifestation.classifications.present?
        @item.call_number = @manifestation.classifications.first.classification_identifier
      end
    else
      @item.circulation_status = CirculationStatus.where(:name => 'Not Available').first unless @item.try(:circulation_status)
      @item.checkout_type = CheckoutType.where(:name => 'article').first unless @item.try(:checkout_type)
      @item.use_restriction_id = UseRestriction.where(:name => 'Not For Loan').select(:id).first.id unless @item.use_restriction_id
      @item.shelf = @library.article_shelf unless @item.try(:shelf)
    end
    @item.acquired_at_string = Date.today unless @item.acquired_at_string
    prepare_options
    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @item }
    end
  end

  # GET /items/1/edit
  def edit
    @item.library_id = @item.shelf.library_id
    @item.use_restriction_id = @item.use_restriction.id if @item.use_restriction
    prepare_options
  end

  # POST /items
  # POST /items.json
  def create
    @item = Item.new(params[:item])

    @manifestation = Manifestation.find(@item.manifestation_id)

    respond_to do |format|
      begin
        Item.transaction do
          @item.manifestation = @manifestation
          @item.save!
          if @item.shelf
            @item.shelf.library.agent.items << @item
          end
          if @item.manifestation.next_reserve
            #ReservationNotifier.deliver_reserved(@item.manifestation.next_reservation.user)
            flash[:message] = t('item.this_item_is_reserved')
            @item.set_next_reservation if @item.available_for_retain?
          end
        end
        if @item.manifestation.series_statement and @item.manifestation.series_statement.periodical
          Manifestation.find(@item.manifestation.series_statement.root_manifestation_id).index
        end
        flash[:notice] = t('controller.successfully_created', :model => t('activerecord.models.item'))
        @item.post_to_union_catalog if LibraryGroup.site_config.post_to_union_catalog
        if @agent
          format.html { redirect_to agent_item_url(@agent, @item) }
          format.json { render :json => @item, :status => :created, :location => @item }
        else
          format.html { redirect_to(@item) }
          format.json { render :json => @item, :status => :created, :location => @item }
        end
      rescue => e
        logger.error "################ #{e.message} ##################"
        prepare_options
        format.html { render :action => "new" }
        format.json { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /items/1
  # PUT /items/1.json
  def update
    if params[:item][:claim_attributes]
      if params[:item][:claim_attributes][:claim_type_id].blank? && params[:item][:claim_attributes][:note].blank?
        params[:item][:claim_attributes][:_destroy] = 1
      end
    end
    if params[:item][:item_has_operators_attributes]
      params[:item][:item_has_operators_attributes].each do |key, operator_attributes|
        if operator_attributes[:username].blank? && operator_attributes[:note].blank?
          params[:item][:item_has_operators_attributes]["#{key}"][:_destroy] = 1
        end
      end
    end

    respond_to do |format|
      if @item.update_attributes(params[:item])
        if @item.manifestation.series_statement and @item.manifestation.series_statement.periodical
          Manifestation.find(@item.manifestation.series_statement.root_manifestation_id).index
        end
        unless @item.remove_reason.nil?
          if @item.reserve
            @item.reserve.revert_request rescue nil
          end
          flash[:notice] = t('item.item_removed')
        else
          flash[:notice] =  t('controller.successfully_updated', :model => t('activerecord.models.item'))
        end
        format.html { redirect_to @item }
        format.json { head :no_content }
      else
        prepare_options
        unless params[:item][:remove_reason_id]
          format.html { render :action => "edit" }
        else
          @remove_reasons = RemoveReason.all
          @remove_id = CirculationStatus.where(:name => "Removed").first.id rescue nil
          flash[:notice] = t('item.update_failed')
          format.html { render :action => "remove" }
        end
        format.json { render :json => @item.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /items/1
  # DELETE /items/1.json
  def destroy
    manifestation = @item.manifestation
    if @item.reserve
      @item.reserve.revert_request rescue nil
    end
    @item.destroy

    respond_to do |format|
      flash[:notice] = t('controller.successfully_deleted', :model => t('activerecord.models.item'))
      if @item.manifestation
        format.html { redirect_to manifestation_items_url(manifestation) }
        format.json { head :no_content }
      else
        format.html { redirect_to items_url }
        format.json { head :no_content }
      end
    end
  end

  def remove
    @remove_reasons = RemoveReason.all
    @remove_id = CirculationStatus.where(:name => "Removed").first.id rescue nil
    respond_to do |format|
      format.html # remove.html.erb
      format.json { render :json => @item }
    end
  end

  def restore
    @item.circulation_status = CirculationStatus.where(:name => "In Process").first rescue nil
    @item.remove_reason = nil
    respond_to do |format|
      if @item.save
        flash[:notice] = t('item.item_restored')
        format.html { redirect_to item_url(@item) }
        format.json { head :no_content }
      else
        flash[:notice] = t('item.update_failed')
        format.html { redirect_to item_url(@item) }
        format.json { head :no_content }
      end
    end
  end

  def upload_to_nacsis
    result = NacsisCat.upload_info_to_nacsis(params[:item_id], params[:db_type], params[:command])

    if result[:return_code] == '200'
      model_str = t('external_catalog.nacsis') + t('activerecord.models.item')
      case params[:command]
      when 'insert'
        flash[:notice] = t('controller.successfully_created', :model => model_str)
      when 'update'
        flash[:notice] = t('controller.successfully_updated', :model => model_str)
      when 'delete'
        flash[:notice] = t('controller.successfully_deleted', :model => model_str)
      end
      flash[:notice] += " #{t('activerecord.attributes.manifestation.hold_id')} : #{result[:result_id]}"
    else
      flash[:notice] = "#{t('resource_import_nacsisfiles.upload_failed')} CODE = #{result[:return_code]} (#{result[:return_phrase]})"
    end

    respond_to do |format|
      format.html { redirect_to item_url(params[:item_id]) }
    end
  end

  def numbering
    item_identifier = params[:type].present? ? Numbering.do_numbering(params[:type]) : nil
    render :json => {:success => 1, :item_identifier => item_identifier}
  end

  private

  def prepare_options
    @libraries = Library.real
    @libraries.delete_if {|l| l.shelves.empty?}
    if @item.new_record?
      @library = Library.real.first(:order => :position, :include => :shelves)
    else
      @library = @item.shelf.library rescue nil
    end
    @circulation_statuses = CirculationStatus.all
    @circulation_statuses.reject!{|cs| cs.name == "Removed"}
    @accept_types = AcceptType.all
    @remove_reasons = RemoveReason.all
    @retention_periods = RetentionPeriod.all
    @use_restrictions = UseRestriction.available
    @bookstores = Bookstore.all
    if @manifestation and !@manifestation.try(:manifestation_type).try(:is_article?)
      @checkout_types = CheckoutType.available_for_carrier_type(@manifestation.carrier_type)
    else
      @checkout_types = CheckoutType.all
    end
    @roles = Role.all
    @numberings = Numbering.where(:numbering_type => 'item')
    @shelf_categories = Shelf.try(:categories) rescue nil
    if @shelf_categories
      @shelves = []
      @shelves << @item.shelf if @item
    else
      @shelves = @library.shelves
    end
    @claim_types = ClaimType.all
    if SystemConfiguration.get('manifestation.use_item_has_operator')
      if @item.item_has_operators.blank?
        @item.item_has_operators << ItemHasOperator.new(:operated_at => Date.today.to_date, :library_id => @item.library_id)
      end
    end
    @location_symbols = Keycode.where(:name => 'item.location_symbol')
    @statistical_classes = Keycode.where(:name => 'item.statistical_class')
    @location_categories = Keycode.where("name = ? AND (ended_at < ? OR ended_at IS NULL)", "item.location_category", Time.zone.now) rescue nil
  end

  def check_status
    if @item.circulation_status.name == "Removed"
      flash[:notice] = t('item.already_removed')
      redirect_to item_url(@item)
    end
    return true
  end

end

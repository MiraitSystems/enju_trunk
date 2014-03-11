class OrdersController < ApplicationController
  #before_filter :check_client_ip_address
  #authorize_function
  load_and_authorize_resource
  before_filter :get_manifestation

  # GET /orders
  # GET /orders.json
  def index
    if params[:manifestation_id]
      @orders = Order.where(["manifestation_id = ?",params[:manifestation_id]]).order("publication_year DESC, order_identifier DESC").page(params[:page])
      @manifestation = Manifestation.find(params[:manifestation_id])
    else
      @orders = Order.order("publication_year DESC, order_identifier DESC").page(params[:page])
    end

    set_select_years

    # 検索オブジェクトの生成と検索の実行
#    search_opts = make_index_plan # 検索動作の方針を抽出する
#    search = factory.new_search
#    do_file_output_proccess(search_opts, search) and return

    respond_to do |format|
      format.html # index.html.erb
      format.json { render :json => @orders }
      format.rss
      format.atom
      format.csv
    end
  end

  def output_excelx
    puts '==============output_excelx=========================='
    index
  end

  # indexアクションにおける各種形式のファイルでの出力を行う。
  # ファイル送信するか、バックグラウンド処理をした旨の通知を行ったらtrueを返す。
  #
  #  * search_opts - 検索条件
  #  * search - 検索に用いるオブジェクト(Sunspotなど)
  def do_file_output_proccess(search_opts, search)
    return false unless search_opts[:index] == :local
    return false unless search_opts[:output_mode]

    # TODO: 第一引数にparamsまたは生成した検索語、フィルタ指定を渡すようにして、バックグラウンドファイル生成で一時ファイルを作らなくて済むようにする
    summary = @query.present? ? "#{@query} " : ""
    summary += advanced_search_condition_summary
    Manifestation.generate_manifestation_list(search[:all], search_opts[:output_type], current_user, summary, search_opts[:output_cols]) do |output|
      send_opts = {
        :filename => output.filename,
        :type => output.mime_type || 'application/octet-stream',
      }
      case output.result_type
      when :path
        send_file output.path, send_opts
      when :data
        send_data output.data, send_opts
      when :delayed
        flash[:message] = t('manifestation.output_job_queued', :job_name => output.job_name)
        redirect_to manifestations_path(params.dup.tap {|h| h.delete_if {|k, v| /\Aoutput/ =~ k || /\Acol/ =~ k} })
      else
        msg = "unknown result type: #{output.result_type.inspect} (bug?)"
        logger.error msg
        raise msg
      end
    end

    true
  end

  # indexアクションのおおまかな動作を決める
  # いくつかのパラメータの検査と整理を行う。
  def make_index_plan
    search_opts = {
      :index => :local,
    }

    if params[:mode] == 'add'
      search_opts[:add_mode] = true
      access_denied unless current_user.has_role?('Librarian')
      @add = true
    end
    if params[:format] == 'csv'
      search_opts[:csv_mode] = true

    elsif params[:format] == 'oai'
      search_opts[:oai_mode] = true
      @oai = check_oai_params(params)

    elsif params[:format] == 'sru'
      search_opts[:sru_mode] = true
      raise InvalidSruOperationError unless params[:operation] == 'searchRetrieve'

    elsif params[:api] == 'openurl'
      search_opts[:openurl_mode] = true

    elsif defined?(EnjuBookmark) && params[:view] == 'tag_cloud'
      search_opts[:tag_cloud_mode] = true
    elsif params[:output]
      search_opts[:output_mode] = true
      search_opts[:output_type] =
        case params[:format_type]
        when 'excelx'  then :excelx
        when 'tsv'     then :tsv
        when 'pdf'     then :pdf
        when 'request' then :request
        when 'label'   then :label
        end
      raise UnknownFileTypeError unless search_opts[:output_type]
      search_opts[:output_cols] = params[:cols]

    elsif params[:format].blank? || params[:format] == 'html'
      search_opts[:html_mode] = true
      if params[:index] == 'nacsis'
        # NOTE: 検索ソースをlocal以外にできるのはformatがhtmlのときだけの限定。
        search_opts[:index] = :nacsis
      end
      if search_opts[:index] == :local &&
          params[:solr_query].present?
        search_opts[:solr_query_mode] = true
      end

      if params[:item_identifier].present? &&
            params[:item_identifier] !~ /\*/ ||
          SystemConfiguration.get('manifestation.isbn_unique') &&
            params[:isbn].present? && params[:isbn] !~ /\*/
        search_opts[:direct_mode] = true
      end

      # split option (local)
      search_opts[:split_by_type] = SystemConfiguration.get('manifestations.split_by_type')
      if search_opts[:split_by_type] && search_opts[:index] == :local
        if params[:without_article]
          search_opts[:with_article] = false
        else
          search_opts[:with_article] = !SystemConfiguration.isWebOPAC || clinet_is_special_ip?
        end
      end

      # split option (nacsis)
      search_opts[:nacsis_search_each] = SystemConfiguration.get('nacsis.search_each')
      if search_opts[:nacsis_search_each] && search_opts[:index] == :nacsis
        search_opts[:with_serial] = true
      end
    end

    # prepare: per_page
    per_page = 65534
    per_page = cookies[:per_page] if cookies[:per_page] # XXX: セッションデータに格納してはダメ?
    per_page = params[:per_page] if params[:per_page]#Manifestation.per_page

    cookies.permanent[:per_page] = { :value => per_page } # XXX: セッションデータに格納してはダメ?
    search_opts[:per_page] = per_page

    # prepare: page
    if search_opts[:oai_mode]
      search_opts[:page] = next_page_number_for_oai_search
    else
      search_opts[:page] = params[:page].try(:to_i) || 1
      search_opts[:page_article] = params[:page_article].try(:to_i) || 1
      search_opts[:page_serial] = params[:page_serial].try(:to_i) || 1
    end
    search_opts[:page_session] = 1
    search_opts[:per_page_session] = SystemConfiguration.get("max_number_of_results")

    search_opts
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
      @order.set_probisional_identifier(Date.today.year.to_i + 1)
      @order.order_day = Date.new((Date.today + 1.years).year, original_order.order_day.month, original_order.order_day.day)
      @order.publication_year = Date.today.year.to_i + 1
      @order.paid_flag = 0
      @order.buying_payment_year = nil
      @order.prepayment_settlements_of_account_year = nil
    else
      @order.order_day = Date.today
      @order.set_probisional_identifier
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
        @order.set_yen_imprest if params[:order_auto_calculation][:flag] == '1'
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
        @order.set_yen_imprest if params[:order_auto_calculation][:flag] == '1'
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

    @order = Order.find(params[:order_id])
    @flag =  self.class.helpers.get_paid_flag
    @order.paid_flag = @flag.id if @flag
    @order.save
    Payment.create_paid(params[:order_id])

    respond_to do |format|
      flash[:notice] = t('controller.successfully_created', :model => t('payment.paid'))
      format.html {redirect_to(order_path(@order, :return_index => params[:return_index]))}
    end
  end

  def search

    where_str = ""

    unless params[:order_identifier].blank?
      if params[:index] == 'startwith_term'
        where_str += "order_identifier like '#{params[:order_identifier]}%%' "
        order = ''
      else
        where_str += "order_identifier = '#{params[:order_identifier]}'"
        order = Order.find_by_order_identifier(params[:order_identifier])
      end

      flash.now[:message] = t('order.no_matches_found_order', :attribute => t('activerecord.attributes.order.order_identifier')) unless order
    end

    unless params[:publication_year].blank?
      where_str += " AND " unless where_str.empty?
      where_str += "publication_year = #{params[:publication_year].to_i}"
    end

    if where_str.empty?
      @orders = Order.order("publication_year DESC, order_identifier DESC").page(params[:page])
    else
      @orders = Order.where([where_str]).order("publication_year DESC, order_identifier DESC").page(params[:page])

      @selected_title = @orders.first.manifestation.original_title if (@orders.size == 1 && params[:order_identifier].present?)
    end

    @selected_order = params[:order_identifier]
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

  def create_subsequent_year_orders

    if params[:order_identifier].blank?
      @orders = Order.where(["publication_year = ?", params[:year].to_i])
    else
      @orders = Order.where(["publication_year = ? AND order_identifier = ?", params[:year].to_i, params[:order_identifier]])
    end

    create_count = 0
    @orders.each do |order|
      if order.order_form && order.order_form.v == '1'
        @new_order = order.dup
        @new_order.set_probisional_identifier(Date.today.year.to_i + 1)
        @new_order.order_day = Date.new((Date.today + 1.years).year, order.order_day.month, order.order_day.day)
        @new_order.publication_year = Date.today.year.to_i + 1
        @new_order.paid_flag = 0
        @new_order.buying_payment_year = nil
        @new_order.prepayment_settlements_of_account_year = nil
        @new_order.save
        create_count += 1
      end
    end
 
    if create_count != 0   
      flash[:notice] = t('controller.successfully_created', :model => t('order.subsequent_year_orders'))
    else
      flash[:message] = t('order.no_create_subsequent_year_orders')
    end

    redirect_to :action => "search", :publication_year => params[:year], :test => "test", :order_identifier => params[:order_identifier]

  end

end

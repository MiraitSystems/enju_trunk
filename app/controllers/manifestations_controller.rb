# -* encoding: utf-8 -*-
class ManifestationsController < ApplicationController
  authorize_function
  add_breadcrumb "I18n.t('breadcrumb.search_manifestations')", 'manifestations_path', :only => [:index] #, :unless => proc{params}
#  add_breadcrumb "I18n.t('breadcrumb.search_manifestations')", 'manifestations_path(params)', :only => [:index], :if => proc{params}
  add_breadcrumb "I18n.t('page.showing', :model => I18n.t('activerecord.models.manifestation'))", 'manifestation_path(params[:id])', :only => [:show]
  add_breadcrumb "I18n.t('page.new', :model => I18n.t('activerecord.models.manifestation'))", 'new_manifestation_path', :only => [:new, :create]
  add_breadcrumb "I18n.t('page.edit', :model => I18n.t('activerecord.models.manifestation'))", 'edit_manifestation_path(params[:id])', :only => [:edit, :update]

  load_and_authorize_resource :except => [:index, :show_nacsis, :create_from_nacsis, :output_show, :output_pdf, :search_manifestation, :numbering]
  authorize_resource :only => :index

  before_filter :authenticate_user!, :only => :edit
  before_filter :get_agent
  before_filter :get_series_statement, :only => [:index, :new, :edit, :output_excelx]
  before_filter :prepare_options, :only => [:new, :edit]
  before_filter :get_version, :only => [:show, :output_show, :output_pdf]
  after_filter :solr_commit, :only => [:create, :up, :outputdate, :destroy]
  after_filter :convert_charset, :only => :index

  helper_method :get_manifestation, :get_subject
  helper_method :get_libraries

  include EnjuOai::OaiController if defined?(EnjuOai)
  include EnjuSearchLog if defined?(EnjuSearchLog)
  include ApplicationHelper
  include ManifestationsHelper
  include FormInputUtils

  class Error < RuntimeError; end
  class InvalidSruOperationError < Error; end
  class UnknownFileTypeError < Error; end

  rescue_from InvalidSruOperationError do |ex|
    render :template => 'manifestations/explain', :layout => false
  end

  rescue_from UnknownFileTypeError do |ex|
    render_404_invalid_format
  end

  class NacsisCatSearch
    # sunspot_solrのSearchオブジェクトとの互換層

    include FormInputUtils

    def initialize(dbs = [:all])
      @orig_dbs = @dbs = dbs
      @db_opts = {}
      @dbs.each {|db| @db_opts[db] = {} }
      @cond = {}

      @results = nil
    end
    attr_accessor :results

    # 検索を実行する
    # 検索条件に問題があった場合にはnilを返す
    def execute
      return nil unless valid?

      if @dbs.blank?
        @results = {}

      else
        cond = @cond.merge(dbs: @dbs)
        @dbs.each do |db|
          next if @db_opts[db].blank?

          cond[:opts] ||= {}
          cond[:opts][db] ||= {}
          @db_opts[db].each_pair do |k, v|
            cond[:opts][db][k] = v
          end
        end
        @results = NacsisCat.search(cond)
      end
      self
    end

    def total; @results.total end
    def collation; nil end

    def setup_paginate!(db, page, per_page)
      @db_opts[db] ||= {}
      @db_opts[db][:page] = normalize_integer(page)
      @db_opts[db][:per_page] = normalize_integer(per_page)
    end

    def filter_by_record_type!(form_input)
      return if @dbs == [:all]
      return if form_input.blank? # DB指定がなければ生成時の指定に従って検索する

      db_param = [form_input].flatten
      db_names = db_param.map {|x| normalize_query_string(x).to_sym }

      @dbs = @dbs&db_names
    end

    def filter_by_ncid!(form_input)
      filter_by_one_word(:id, form_input)
    end
    def filter_by_isbn!(form_input)
      filter_by_one_word(:isbn, form_input)
    end
    def filter_by_issn!(form_input)
      filter_by_one_word(:issn, form_input)
    end
    def filter_by_ndc!(form_input)
      filter_by_one_word(:ndc, form_input)
    end
    def filter_by_edition_display_value!(form_input)
      filter_by_one_word(:edition_display_value, form_input)
    end
    def filter_by_volume_number_string!(form_input)
      filter_by_one_word(:volume_number_string, form_input)
    end
    def filter_by_issue_number_string!(form_input)
      filter_by_one_word(:issue_number_string, form_input)
    end
    def filter_by_serial_number_string!(form_input)
      filter_by_one_word(:serial_number_string, form_input)
    end

    def filter_by_query!(form_input, inverse = false)
      filter_by_some_words(:query, form_input, inverse)
    end
    def filter_by_title!(form_input, inverse = false)
      filter_by_some_words(:title, form_input, inverse)
    end
    def filter_by_creator!(form_input, inverse = false)
      filter_by_some_words(:author, form_input, inverse)
    end
    def filter_by_publisher!(form_input, inverse = false)
      filter_by_some_words(:publisher, form_input, inverse)
    end
    def filter_by_subject!(form_input, inverse = false)
      filter_by_some_words(:subject, form_input, inverse)
    end

    private

    def valid?
      true
    end

    def filter_by_one_word(name, form_input)
      query = each_query_word(form_input, false)
      return if query.blank?

      @cond[name] = query.map {|word| unquote_query_word(word) }.join(' ')
    end

    def filter_by_some_words(name, form_input, inverse)
      query = each_query_word(form_input, false)
      return if query.blank?

      words = query.map {|word| unquote_query_word(word) }
      if inverse
        @cond[:except] ||= {}
        @cond[:except][name] = words
      else
        @cond[name] = words
      end
    end
  end

  class SearchFactory
    def initialize(options, params)
      @options = options
      @params = params

      @logger = ::Rails.logger

      setup!
    end
    attr_reader :options, :params, :logger

    def facet_fields
      []
    end

    # 検索オブジェクトにfacetの設定を加える
    def setup_facet!(search)
    end

    # 検索オブジェクトにページネイトの設定を加える
    def setup_paginate!(search, page, per_page)
    end

    # 検索オブジェクトに「もしかして」の設定を加える
    def setup_collation!(search, form_input)
    end

    private

    def setup!
    end
  end

  class LocalSearchFactory < SearchFactory
    FACET_FIELDS = [
      :reservable, :carrier_type, :language, :library, :manifestation_type,
      :missing_issue, :in_process, :circulation_status_in_process,
      :circulation_status_in_factory, :no_item
    ]

    class Container
      def initialize(options, params)
        @options = options
        @params = params
        @search = {}
      end

      def [](key)
        @search[key]
      end

      def []=(key, value)
        @search[key] = value
      end

      def facet_fields
        FACET_FIELDS
      end

      def execute
        [:all, :book, :article, :serial].map do |key|
          @search[key].try(:execute)
        end
      end

      def setup_collation!(query)
        options = @options
        @search[:all].build do
          spellcheck :collate => 3, :q => query if options[:html_mode]
        end
      end

      def setup_facet!
        [:all, :book].each do |key| 
          if @search[key]
            @search[key].build do
              facet_fields.each {|f| facet f }
            end
          end
        end
      end

      def setup_paginate!
        @search.each_pair do |key, s|
          if key == :article
            setup_paginate_internal!(s, @options[:page_article], @options[:per_page])
          elsif key == :serial
            setup_paginate_internal!(s, @options[:page_serial], @options[:per_page])
          elsif key == :session
            setup_paginate_internal!(s, @options[:page_session], @options[:per_page_session])
          else
            # :all or :book
            setup_paginate_internal!(s, @options[:page], @options[:per_page])
          end
        end
      end

      private

        def setup_paginate_internal!(search, page, per_page)
          if @options[:sru_mode]
            search.query.start_record(@params[:startRecord] || 1, @params[:maximumRecords] || 200)
          else
            search.build do
              paginate :page => page, :per_page => per_page
            end
          end
        end
    end

    def initialize(options, params, query, with_filter, without_filter, sort)
      @query = query
      @with_filter = with_filter
      @without_filter = without_filter
      @sort = sort

      super(options, params)
    end
    attr_reader :query, :sort

    def new_search
      container = Container.new(options, params)

      # 全種の書誌からの横断検索用
      container[:all] = new_search_internal(:all)

      # session[:manifestation_ids]更新のための検索用
      # FIXME?
      # session[:manifestation_ids]は検索結果の書誌情報を次々と見るのに使われている
      # (manifestations/index→manifestations/show→manifestations/show→...)。
      # よって文献とその他を分ける場合には、このデータも分けて取りまわす必要があるはず。
      container[:session] = new_search_internal(:all)

      if options[:split_by_type]
        # 一般書誌のみの検索用
        container[:book] = new_search_internal(:book)
        if options[:with_article]
          # 資料書誌のみの検索用
          container[:article] = new_search_internal(:article)
        end
        if options[:with_serial]
          # 雑誌書誌のみの検索用
          container[:serial] = new_search_internal(:serial)
        end
      end

      container
    end

    # 新しい検索オブジェクトを生成する。
    #  * manifestation_type - 検索対象とする書誌のタイプ(:all、:book、:article)を指定する。
    def new_search_internal(manifestation_type = :all)
      search = Sunspot.new_search(Manifestation)

      Manifestation.build_search_for_manifestations_list(search, @query, @with_filter, @without_filter)

      unless options[:add_mode]
        includes = [
          :carrier_type, :required_role, :items, :creators, :contributors,
          :publishers,
        ]
        includes << :bookmarks if defined?(EnjuBookmark)
        search.data_accessor_for(Manifestation).include = includes
      end

      search.build do
        if options[:oai_mode]
          order_by :updated_at, :desc
        else
          order_by sort[:sort_by], sort[:order]
          order_by :created_at, :desc
        end

        case manifestation_type
        when :book
          with(:is_article).equal_to false
        when :article
          with(:is_article).equal_to true
        else # :all
          # noop
        end
      end

      if options[:html_mode] && params[:missing_issue].nil?
        search.data_accessor_for(Manifestation).select = [
          :id, :original_title, :title_transcription, :required_role_id,
          :manifestation_type_id, :carrier_type_id, :access_address,
          :volume_number_string, :issue_number_string, :serial_number_string, :serial_number,
          :date_of_publication, :pub_date, :periodical_master,
          :carrier_type_id, :created_at, :note, :missing_issue, :article_title,
          :start_page, :end_page, :exinfo_1, :exinfo_6, :identifier
        ]
      end

      search
    end
    private :new_search_internal
  end

  class NacsisCatSearchFactory < SearchFactory
    class Container
      def initialize(options, search)
        @options = options
        @search = search
      end
      attr_reader :search

      def [](key)
        # 複数DBが指定された検索であっても
        # ゲートウェイへのアクセスは1回だけにする仕様であるため、
        # LocalSearchFactory::Containerとは異なって
        # 書誌の種別ごとの検索オブジェクトを持たない。
        # そのため、ここでは共通の@searchを常に返している。
        #
        # しかし、このままでは共通の@searchを介した
        # 複数回アクセスが発生してしまう可能性があるので
        # memoizeすななど何らかの対策が必要となる。
        # (ただし、2013-11-12時点では
        # 各種幅検索をともなう機能はローカル検索のみに
        # 対応しており、上述の問題が顕在化することはない。)
        @search
      end

      def facet_fields
        []
      end

      def execute
        results = @search.execute.results

        [:all, :book, :article, :serial].map do |key|
          NacsisCatSearch.new.tap do |x|
            if results.include?(key)
              x.results = results[key]
            else
              x.results = NacsisCat::ResultArray.new(nil)
            end
          end
        end
      end

      def setup_collation!(query)
        # noop
      end

      def setup_facet!
        # noop
      end

      def setup_paginate!
        @search.setup_paginate!(:all,     @options[:page],         @options[:per_page])
        @search.setup_paginate!(:book,    @options[:page],         @options[:per_page])
        @search.setup_paginate!(:article, @options[:page_article], @options[:per_page])
        @search.setup_paginate!(:serial,  @options[:page_serial],  @options[:per_page])
        @search.setup_paginate!(:session, @options[:page_session], @options[:per_page_session])
      end
    end

    def new_search
      dbs = []
      if @options[:nacsis_search_each]
        dbs << :book
        if @options[:with_article]
          dbs << :article
        end
        if @options[:with_serial]
          dbs << :serial
        end
      else
        dbs << :all
      end

      search = NacsisCatSearch.new(dbs)

      search.filter_by_record_type!(params[:manifestation_type])

      [
        :isbn, :issn, :ndc, :ncid,
        :edition_display_value, :volume_number_string, :issue_number_string, :serial_number_string,
      ].each do |name|
        search.__send__(:"filter_by_#{name}!", params[name])
      end

      [:query, :title, :creator, :publisher, :subject].each do |name|
        search.__send__(:"filter_by_#{name}!", params[name])
        search.__send__(:"filter_by_#{name}!", params[:"except_#{name}"], true)
      end

      Container.new(@options, search)
    end
  end

  # GET /manifestations
  # GET /manifestations.json
  def index
    set_reserve_user
    search_opts = make_index_plan # 検索動作の方針を抽出する

    @seconds = Benchmark.realtime do
      next if @oai && @oai[:need_not_to_search]
      do_oai_get_record_process(search_opts) and return
      do_direct_mode_process(search_opts) and return

      # indexアクションで使用する
      # 主要インスタンス変数の処期化

      @count = {}
      set_reservable
      get_manifestation
      get_subject
      set_in_process
      @index_agent = get_index_agent
      @per_page = search_opts[:per_page]
      @all_manifestations = params[:all_manifestations] if params[:all_manifestations]

      @libraries = Library.real.all
      @search_engines = Rails.cache.fetch('search_engine_all') { SearchEngine.all }

      if params[:bookbinder_id]
        @binder = Item.find(params[:bookbinder_id]) rescue nil
        @all_manifestations = params[:all_manifestations] = true
      end

      if params[:removed_from].present? || params[:removed_to].present? || params[:removed]
        @removed = true
      end

      if defined?(EnjuTrunkTheme)
        if params[:theme_id]
          @theme = Theme.find(params[:theme_id]) rescue nil
          @all_manifestations = params[:all_manifestations] = false
        end
      end

      if params[:basket_id]
        @basket = @current_basket # ignore params[:basket_id] and get current_basket with current_user
        @all_manifestations = params[:all_manifestations] = true 
      end

      @query = params[:query] # フォームで入力されたメインの検索語を保存する

      # 検索オブジェクトのfactoryを生成する
      #
      # NOTE:
      # 検索システムに合わせた検索条件の生成などはfactoryにおいて実装する。
      # ただしlocal検索については過去の経緯から特別扱いとなっており、
      # 検索条件生成コードのほとんどがコントローラに実装されている。
      if search_opts[:index] == :nacsis
        factory = NacsisCatSearchFactory.new(search_opts, params)

      else
        if search_opts[:sru_mode]
          sru = Sru.new(params)
          query = sru.cql.to_sunspot
          sort = sru.sort_by
        elsif search_opts[:openurl_mode]
          openurl = Openurl.new(params)
          query = openurl.query_text
          sort = search_result_order(params[:sort_by], params[:order])
        else
          if search_opts[:solr_query_mode]
            query = params[:solr_query]
          else
            query, highlight = make_query_string_and_hl_pattern
            @highlight = /(#{Regexp.union(highlight)})/
          end
          @solr_query = query # フォーム入力から生成したSolr検索式
          sort = search_result_order(params[:sort_by], params[:order])
        end
        logger.debug "  SOLR Query string:<#{@solr_query}>"

        with_filter, without_filter = make_query_filter(search_opts)
        factory = LocalSearchFactory.new(search_opts, params, @solr_query, with_filter, without_filter, sort)
      end
      # 検索オブジェクトの生成と検索の実行

      search = factory.new_search

      do_file_output_proccess(search_opts, search) and return

      search.setup_collation!(@query)
      search.setup_facet!
      search.setup_paginate! unless request.xhr?

      begin
        search_all_result, search_book_result,
          search_article_result, search_serial_result = search.execute
      rescue Exception => e
        flash[:message] = t('manifestation.invalid_query')
        logger.error "query error: #{e} (#{e.class})"
        e.backtrace.each {|bt| logger.debug "\t#{bt}" }
        return
      end

      update_search_sessions(search_opts, search)
      do_tag_cloud_process(search_opts) and return

      # 主にビューのためのインスタンス変数を設定する

      sum = 0
      @manifestations_all = []
      [
        ['', search_all_result, :page],
        ['_book', search_book_result, :page],
        ['_article', search_article_result, :page_article],
        ['_serial', search_serial_result, :page_serial],
      ].each do |ivsfx, sr, po|
        next unless sr

        @count[:"query_result#{ivsfx}"] = sr.total
        sum += sr.total

        ary = Kaminari.paginate_array(
          sr.results,
          :total_count => total_search_result_count(sr)
        ).page(search_opts[po]).per(search_opts[:per_page])
        @manifestations_all << ary

        instance_variable_set(:"@manifestations#{ivsfx}", ary)

        if search_opts[:index] == :nacsis && (ivsfx == '_book' || ivsfx == '_serial')
          session.delete("nacsis_cat#{ivsfx}_ids")
          ncid_ary = []
          ary.each do |nacsis_cat|
            ncid_ary << nacsis_cat.try(:ncid)
          end
          session["nacsis_cat#{ivsfx}_ids"] = ncid_ary unless ncid_ary.empty?
        end
      end
      session[:params] = params if search_opts[:index] == :nacsis

      @count[:query_result] = sum
      @collation = search_all_result.collation if @count[:query_result] == 0

      if current_user.nil? or !current_user.has_role?('Librarian') 
        save_search_history(@solr_query, @manifestations.limit_value, @count[:query_result], current_user)
      end

      if @manifestations_all.blank?
        # 分割表示していない場合
        @manifestations_all << @manifestations
      end

      if search_opts[:html_mode]
        s = search_opts[:split_by_type] && !search_opts[:with_article] ? search_book_result : search_all_result
        search.facet_fields.each do |field|
          instance_variable_set(:"@#{field}_facet", s.facet(field).rows)
        end
      end

      # TODO: 検索結果が少ない場合にも表示させる
      #
      # NOTE:
      # 大本のコード(enju_trunkではないenju)をそのまま残したため
      # @solr_query(solr用の検索式)から推奨タグを導出しているが、
      # フォームで入力された検索語から導出したほうが適切ということはないか?
      if search_opts[:index] == :local &&
          search_all_result.results.blank? &&
          defined?(EnjuBookmark) &&
          @solr_query.respond_to?(:suggest_tags)
        @suggested_tag = @solr_query.suggest_tags.first
      end
    end

    store_location # before_filter ではファセット検索のURLを記憶してしまう
    
    respond_to do |format|
      if params[:opac]
        if @manifestations.size > 0
          format.html { render :template => 'opac/manifestations/index', :layout => 'opac' }
        else
          flash[:notice] = t('page.no_record_found')
          format.html { render :template => 'opac/search', :layout => 'opac' }
        end
      end
      format.html
      format.mobile
      format.xml  { render :xml => @manifestations }
      format.sru  { render :layout => false }
      format.rss  { render :layout => false }
      format.csv  { render :layout => false }
      format.rdf  { render :layout => false }
      format.atom
      format.oai {
        if @manifestations.blank?
          @oai[:errors] << 'noRecordsMatch'
        else
          from_and_until_times = set_from_and_until(Manifestation, params[:from], params[:until])
          from_time = from_and_until_times[:from] || Manifestation.last.updated_at
          until_time = from_and_until_times[:until] || Manifestation.first.updated_at
          set_resumption_token(params[:resumptionToken], from_time, until_time)
        end

        case params[:verb]
        when 'Identify'
          render :template => 'manifestations/identify'
        when 'ListMetadataFormats'
          render :template => 'manifestations/list_metadata_formats'
        when 'ListSets'
          @series_statements = SeriesStatement.select([:id, :original_title])
          render :template => 'manifestations/list_sets'
        when 'ListIdentifiers'
          render :template => 'manifestations/list_identifiers'
        when 'ListRecords'
          render :template => 'manifestations/list_records'
        end
      }
      format.mods
      format.json { render :json => @manifestations }
      format.js { 
        case params[:verb]
        when 'Exchange'
          render 'exchange_manifestations/manifestations'
        else
          render 'binding_items/manifestations'
        end
      }
    end
  #rescue QueryError => e
  #  render :template => 'manifestations/error.xml', :layout => false
  #  Rails.logger.info "#{Time.zone.now}\t#{query}\t\t#{current_user.try(:username)}\t#{e}"
  #  return
  end

  def output_excelx
    index
  end

  # GET /manifestations/1
  # GET /manifestations/1.json
  def show
    can_show = true
    unless user_signed_in?
      can_show = false if @manifestation.non_searchable?
    else
      can_show = false if !current_user.has_role?('Librarian') and @manifestation.non_searchable?
    end
    unless can_show
      access_denied
    end

    if params[:isbn].present?
      if @manifestation = Manifestation.find_by_isbn(params[:isbn])
        redirect_to @manifestation
        return
      else
        raise ActiveRecord::RecordNotFound if @manifestation.nil?
      end
    else
      if @version
        @manifestation = @manifestation.versions.find(@version).item if @version
      #else
      #  @manifestation = Manifestation.find(params[:id], :include => [:creators, :contributors, :publishers, :items])
      end
    end

    case params[:mode]
    when 'send_email'
      if user_signed_in?
        Notifier.delay.manifestation_info(current_user, @manifestation)
        flash[:notice] = t('page.sent_email')
        redirect_to @manifestation
        return
      else
        access_denied
      end
    end

    return if render_mode(params[:mode])

    if Setting.operation
      @reserved_count = Reserve.waiting.where(:manifestation_id => @manifestation.id, :checked_out_at => nil).count
      @reserve = current_user.reserves.where(:manifestation_id => @manifestation.id).last if user_signed_in?
    end

    store_location

    if @manifestation.attachment.path
      if Setting.uploaded_file.storage == :s3
        data = open(@manifestation.attachment.url) {|io| io.read }.force_encoding('UTF-8')
      else
        file = @manifestation.attachment.path
      end
    end

    if @manifestation.bookbinder
      @binder = @manifestation.items.where(:bookbinder => true).first rescue nil
    end

    if @manifestation.periodical_master?
      if params[:opac]
        redirect_to series_statement_manifestations_url(@manifestation.series_statement, :opac => true)
      elsif params[:all_manifestations]
        redirect_to series_statement_manifestations_url(@manifestation.series_statement, :all_manifestations => true)
      else
        redirect_to series_statement_manifestations_url(@manifestation.series_statement)
      end
      return
    else
      if @manifestation.series_statement && @manifestation.nacsis_identifier
        redirect_to series_statement_manifestations_url(@manifestation.series_statement)
      end
      return
    end


    respond_to do |format|
      format.html { render :template => 'opac/manifestations/show', :layout => 'opac' } if params[:opac]
      format.html # show.html.erb
      format.mobile
      format.xml  {
        case params[:mode]
        when 'related'
          render :template => 'manifestations/related'
        else
          render :xml => @manifestation
        end
      }
      format.rdf
      format.oai
      format.mods
      format.json { render :json => @manifestation }
      #format.atom { render :template => 'manifestations/oai_ore' }
      #format.js
      format.download {
        if @manifestation.attachment.path
          if Setting.uploaded_file.storage == :s3
            send_data @manifestation.attachment.data, :filename => @manifestation.attachment_file_name.encode("cp932"), :type => 'application/octet-stream'
          else
            send_file file, :filename => @manifestation.attachment_file_name.encode("cp932"), :type => 'application/octet-stream'
          end
        else
          render :template => 'page/404', :status => 404
        end
      }
    end
  end

  # GET /manifestations/new
  # GET /manifestations/new.json
  def new
    @manifestation = Manifestation.new
    @select_theme_tags = Manifestation.struct_theme_selects if defined?(EnjuTrunkTheme)
    original_manifestation = Manifestation.where(:id => params[:manifestation_id]).first
    if original_manifestation # GET /manifestations/new?manifestation_id=1
      @manifestation = original_manifestation.dup
      
      @classifications = get_classification_values(original_manifestation)

      @manifestation.isbn = nil if SystemConfiguration.get("manifestation.isbn_unique")
      @manifestation.series_statement = original_manifestation.series_statement unless @manifestation.series_statement
      @keep_themes = original_manifestation.themes.collect(&:id).flatten.join(',') if defined?(EnjuTrunkTheme)
      if original_manifestation.manifestation_exinfos
        original_manifestation.manifestation_exinfos.each { |e| eval("@#{e.name} = '#{e.value}'") } 
      end
      if original_manifestation.manifestation_extexts
        original_manifestation.manifestation_extexts.each { |e| eval("@#{e.name}_type_id = '#{e.type_id}'; @#{e.name}_value = '#{e.value}'") }
      end
    elsif @series_statement # GET /series_statements/1/manifestations/new
      @manifestation = @series_statement.new_manifestation

      @classifications = get_classification_values(@manifestation)
    end

    @creators = @manifestation.try(:creators).present? ? @manifestation.creators.order(:position) : [{}] unless @creators
    @contributors = @manifestation.try(:contributors).present? ? @manifestation.contributors.order(:position) : [{}] unless @contributors
    @publishers = @manifestation.try(:publishers).present? ? @manifestation.publishers.order(:position) : [{}] unless @publishers
    @subjects = @manifestation.try(:subjects).present? ? @manifestation.subjects.order(:position) : [{}] unless @subjects

    @classifications = get_classification_values(@manifestation) if @classifications.blank?
    
    @manifestation.set_next_number(@manifestation.volume_number, @manifestation.issue_number) if params[:mode] == 'new_issue'

    @original_manifestation = original_manifestation if params[:mode] == 'add'

    if SystemConfiguration.get("manifestation.has_one_item") == true
      @manifestation.items.build
    end

    respond_to do |format|
      format.html # new.html.erb
      format.json { render :json => @manifestation }
    end
  end

  # GET /manifestations/1/edit
  def edit
    unless current_user.has_role?('Librarian')
      unless params[:mode] == 'tag_edit'
        access_denied
      end
    end
    @original_manifestation = Manifestation.where(:id => params[:manifestation_id]).first
    @manifestation.series_statement = @series_statement if @series_statement
    
    @creators = @manifestation.try(:creators).present? ? @manifestation.creators.order(:position) : [{}] unless @creators
    @contributors = @manifestation.try(:contributors).present? ? @manifestation.contributors.order(:position) : [{}] unless @contributors
    @publishers = @manifestation.try(:publishers).present? ? @manifestation.publishers.order(:position) : [{}] unless @publishers
    @subjects = @manifestation.try(:subjects).present? ? @manifestation.subjects.order(:position) : [{}] unless @subjects
    @classifications = get_classification_values(@manifestation)
    
    @manifestation.manifestation_exinfos.each { |e| eval("@#{e.name} = '#{e.value}'") } if @manifestation.manifestation_exinfos
    if @manifestation.manifestation_extexts
      @manifestation.manifestation_extexts.each { |e| eval("@#{e.name}_type_id = '#{e.type_id}'; @#{e.name}_value = '#{e.value}'") } 
    end
    if defined?(EnjuBookmark)
      if params[:mode] == 'tag_edit'
        @bookmark = current_user.bookmarks.where(:manifestation_id => @manifestation.id).first if @manifestation rescue nil
        render :partial => 'manifestations/tag_edit', :locals => {:manifestation => @manifestation}
      end
      store_location unless params[:mode] == 'tag_edit'
    end
    if defined?(EnjuTrunkTheme)
      @select_theme_tags = Manifestation.struct_theme_selects
      @keep_themes = @manifestation.themes.collect(&:id).flatten.join(',')
    end

    if SystemConfiguration.get("manifestation.has_one_item") == true
      @manifestation.items.build if @manifestation.items.blank?
    end

  end

  # POST /manifestations
  # POST /manifestations.json
  def create
    @manifestation = Manifestation.new(params[:manifestation])
    @original_manifestation = Manifestation.where(:id => params[:manifestation_id]).first
    if @manifestation.respond_to?(:post_to_scribd)
      @manifestation.post_to_scribd = true if params[:manifestation][:post_to_scribd] == "1"
    end
    unless @manifestation.original_title?
      @manifestation.original_title = @manifestation.attachment_file_name
    end
    if params[:manifestation][:series_statement_id]
      series_statement = SeriesStatement.find(params[:manifestation][:series_statement_id])
      @manifestation.series_statement = series_statement if  series_statement
    end

    # agents
    @creators = params[:creators]
    @contributors = params[:contributors]
    @publishers = params[:publishers]

    # subjects
    @subjects = params[:subjects] 
    @manifestation.subjects = create_subject_values(@subjects);

    # classifications
    @classifications = params[:classifications] 
    @manifestation.classifications = create_classification_values(@classifications);

    @theme = params[:manifestation][:theme] if defined?(EnjuTrunkTheme)
    params[:exinfos].each { |k, v| eval("@#{k} = '#{v}'") } if params[:exinfos]
    params[:extexts].each { |k, v| eval("@#{k}_type_id = '#{v['type_id']}'; @#{k}_value = '#{v['value']}'") } if params[:extexts]

    respond_to do |format|
      if @manifestation.save
        Manifestation.transaction do
          if @original_manifestation
            @manifestation.derived_manifestations << @original_manifestation
          end
          if @manifestation.series_statement and @manifestation.series_statement.periodical
            Manifestation.find(@manifestation.series_statement.root_manifestation_id).index
          end

          @manifestation.creates = create_creator_values(@creators)
          @manifestation.realizes = create_contributor_values(@contributors)
          @manifestation.produces = create_publisher_values(@publishers)

          @manifestation.themes = Theme.add_themes(@theme) unless @theme.blank? if defined?(EnjuTrunkTheme)
          @manifestation.manifestation_exinfos = ManifestationExinfo.add_exinfos(params[:exinfos], @manifestation.id) if params[:exinfos]
          @manifestation.manifestation_extexts = ManifestationExtext.add_extexts(params[:extexts], @manifestation.id) if params[:extexts]
        end

        format.html { redirect_to @manifestation, :notice => t('controller.successfully_created', :model => t('activerecord.models.manifestation')) }
        format.json { render :json => @manifestation, :status => :created, :location => @manifestation }
      else
        prepare_options

        format.html { render :action => "new" }
        format.json { render :json => @manifestation.errors, :status => :unprocessable_entity }
        if defined?(EnjuTrunkTheme)
          @select_theme_tags = Manifestation.struct_theme_selects
          @keep_themes = @theme
        end
      end
    end
  end

  def numbering
    manifestation_identifier = params[:type].present? ? Numbering.do_numbering(params[:type]) : nil 
    render :json => {:success => 1, :manifestation_identifier => manifestation_identifier}
  end 

  # PUT /manifestations/1
  # PUT /manifestations/1.json
  def update
    if params[:manifestation][:work_has_titles_attributes]
      params[:manifestation][:work_has_titles_attributes].each do |key, title_attributes|
        if title_attributes[:title].blank? && title_attributes[:title_transcription].blank? && title_attributes[:title_alternative].blank?
          params[:manifestation][:work_has_titles_attributes]["#{key}"][:_destroy] = 1
        end
      end
    end
    if params[:manifestation][:identifiers_attributes]
      params[:manifestation][:identifiers_attributes].each do |key, identifier_attributes|
        if identifier_attributes[:body].blank?
          params[:manifestation][:identifiers_attributes]["#{key}"][:_destroy] = 1
        end
      end
    end

    # agents
    @creators = params[:creators]
    @contributors = params[:contributors]
    @publishers = params[:publishers]

    # subjects
    @subjects = params[:subjects]
    @manifestation.subjects = create_subject_values(@subjects);
    
    # classifications
    @classifications = params[:classifications] 
    @manifestation.classifications = create_classification_values(@classifications);

    @theme = params[:manifestation][:theme] if defined?(EnjuTrunkTheme)
    params[:exinfos].each { |k, v| eval("@#{k} = '#{v}'") } if params[:exinfos]
    params[:extexts].each { |k, v| eval("@#{k}_type_id = '#{v['type_id']}'; @#{k}_value = '#{v['value']}'") } if params[:extexts]

    respond_to do |format|
      if @manifestation.update_attributes(params[:manifestation])
        if @manifestation.series_statement and @manifestation.series_statement.periodical
          Manifestation.find(@manifestation.series_statement.root_manifestation_id).index
        end

        @manifestation.creates = create_creator_values(@creators)
        @manifestation.realizes = create_contributor_values(@contributors)
        @manifestation.produces = create_publisher_values(@publishers)

        if defined?(EnjuTrunkTheme)
          @manifestation.themes.destroy_all
          @manifestation.themes = Theme.add_themes(@theme)
        end
        if params[:exinfos]
          @manifestation.manifestation_exinfos = ManifestationExinfo.add_exinfos(params[:exinfos], @manifestation.id)
        end
        if params[:extexts]
          @manifestation.manifestation_extexts = ManifestationExtext.add_extexts(params[:extexts], @manifestation.id)
        end

        format.html { redirect_to @manifestation, :notice => t('controller.successfully_updated', :model => t('activerecord.models.manifestation')) }
        format.json { head :no_content }
      else
        prepare_options

        format.html { render :action => "edit" }
        format.json { render :json => @manifestation.errors, :status => :unprocessable_entity }
        if defined?(EnjuTrunkTheme)
          @select_theme_tags = Manifestation.struct_theme_selects
          @keep_themes = @theme
        end
      end
    end
  end

  # DELETE /manifestations/1
  # DELETE /manifestations/1.json
  def destroy
    if SystemConfiguration.get("manifestation.has_one_item")
      @manifestation.items.each{ |item| item.mark_for_destruction }
    end
    @manifestation.destroy
    flash[:message] = t('controller.successfully_deleted', :model => t('activerecord.models.manifestation'))

    respond_to do |format|
      format.html { redirect_to manifestations_url }
      format.json { head :no_content }
    end
  end

  def output_show
    @manifestation = Manifestation.find(params[:id])
    data = Manifestation.get_manifestation_locate(@manifestation, current_user)
    send_data data.generate, :filename => Setting.manifestation_locate_print.filename
  end

  def output_pdf
    output_show
  end

  # GET /manifestations/nacsis/A001
  def show_nacsis
    case normalize_query_string(params[:manifestation_type])
    when 'book'
      db = :book
    when 'serial'
      db = :serial
    else
      # 想定されないDB
      raise ActiveRecord::RecordNotFound
    end

    search = NacsisCatSearch.new([db])
    search.filter_by_ncid!(params[:ncid])
    retval = search.execute
    raise ActiveRecord::RecordNotFound unless retval
    raise ActiveRecord::RecordNotFound unless retval.results[db].present?

    @nacsis_cat = retval.results[db].first

    db = @nacsis_cat.serial? ? :shold : :bhold
    search = NacsisCatSearch.new([db])
    search.filter_by_ncid!(params[:ncid])
    retval = search.execute
    @items = retval.try(:results).try(:[], db)

    respond_to do |format|
      format.html
    end
  end

  def search_manifestation
    return nil unless request.xhr? or params[:original_title].blank?
    manifestations = Manifestation.search.build do
      with(:original_title).equal_to params[:original_title]
      with(:periodical).equal_to false
    end.execute!.results
    manifestations = manifestations.delete_if{ |m| m.id == params[:manifestation_id].to_i } if params[:manifestation_id]
    return nil unless manifestations.present?
    manifestation_urls = []
    manifestations.each do |m|
      str = "#{t('activerecord.attributes.manifestation.identifier')}:"
      str += m.identifier.to_s
      manifestation_urls << ApplicationController.helpers.link_to(str, manifestation_path(m))
    end
    render :json => { success: 1, manifestation_urls: manifestation_urls }
  end

  # POST /manifestations/create_from_nacsis?ncid=<NCID>&manifestation_type=book
  def create_from_nacsis
    ncid = params['ncid']
    type = params['manifestation_type'] || 'book'

    if type == 'book'
      created_record = Manifestation.where(:nacsis_identifier => ncid).first
      created_record = NacsisCat.create_manifestation_from_ncid(ncid) if created_record.nil?
    else
      created_record = SeriesStatement.where(:nacsis_series_statementid => ncid).first
      created_record = NacsisCat.create_series_statement_from_ncid(ncid) if created_record.nil?
    end

    respond_to do |format|
      format.html do
        if created_record.nil?
          redirect_to nacsis_manifestations_path(ncid: ncid, manifestation_type: type)
        elsif created_record.new_record?
          redirect_to created_record,
            notice: t('controller.successfully_created', :model => t('activerecord.models.manifestation'))
        else
          redirect_to created_record
        end
      end
    end
  end

  def upload_to_nacsis
    result = NacsisCat.upload_info_to_nacsis(params[:work_id], params[:db_type], params[:command])

    case params[:db_type]
    when 'BOOK'
      if params[:series_id]
        redirect_url = series_statement_manifestations_url(params[:series_id], :all_manifestations => true)
      else
        redirect_url = manifestation_url(params[:work_id])
      end
      model_str = t('page.nacsis_book')
    when 'SERIAL'
      redirect_url = series_statement_manifestations_url(params[:work_id], :all_manifestations => true)
      model_str = t('page.nacsis_serial')
    end

    if result[:return_code] == '200'
      model_str = t('external_catalog.nacsis') + model_str + t('resource_import_textfile.book')
      case params[:command]
      when 'insert'
        flash[:notice] = t('controller.successfully_created', :model => model_str)
      when 'update'
        flash[:notice] = t('controller.successfully_updated', :model => model_str)
      end
      flash[:notice] += " #{t('activerecord.attributes.nacsis_user_request.ncid')} : #{result[:result_id]}"
    else
      flash[:notice] = "#{t('resource_import_nacsisfiles.upload_failed')} CODE = #{result[:return_code]} (#{result[:return_phrase]})"
    end

    respond_to do |format|
      format.html { redirect_to redirect_url }
    end
  end

  private

  # solrに送信するqパラメータ文字列を構成する
  # TODO: integerやstringもqfに含める
  # TODO: このメソッドをfactoryに移動する
  def make_query_string_and_hl_pattern
    qwords = []
    highlight = []

    #
    # basic search
    #

    string_fields_for_query = [ # fulltext検索に対応するstring型フィールドのリスト
      :title, :contributor,
      :exinfo_1, :exinfo_6,
      :subject, :isbn, :issn, :identifier,
      # 登録内容がroot_of_series?==trueの場合に相違
      :creator, :publisher,
      # 対応するstring型インデックスがない
      # :fulltext,
      # :article_title, :series_title,
      # :note, :description,
      # :aulast, :aufirst
      # :atitle, :btitle, :jtitle,
      # :extext_1, :extext_2, :extext_3, :extext_4, :extext_5,
    ]

    query = params[:query].to_s
    query = '' if query == '[* TO *]'

    if query.present?
      qws = []
      if params[:query_merge] == 'startwith'
        qws << adhoc_text_field_query(
          "#{escape_query_string(query, true)}*",
          Manifestation, string_fields_for_query)
      else
        each_query_word(normalize_query_string(query)) do |qw|
          highlight << /#{highlight_pattern(qw)}/
          qws << generate_adhoc_string_query_text(qw, Manifestation, string_fields_for_query) do |t|
            qw.size == 1 ? "#{t}*" : nil
          end
        end
      end

      if qws.size == 1
        qwords << qws
      elsif params[:query_merge] == 'all' || params[:query_merge] != 'any' && SystemConfiguration.get("search.use_and")
        qwords << qws.join(' AND ')
      else
        qwords << '(' + qws.join(' OR ') + ')'
      end
    end

    # recent manifestations
    qwords << "created_at_d:[NOW-1MONTH TO NOW] AND except_recent_b:false" if params[:mode] == 'recent'

    #
    # advanced search
    #

    # exact match / start-with match
    special_match = []
    [:title, :creator].each do |key|
      value = params[key]
      merge_type = params[:"#{key}_merge"]
      next unless value.present? && (merge_type == 'exact' || merge_type == 'startwith')
      special_match << key

      case key
      when :title
        field = 'title_sm'
      when :creator
        field = 'creator_sm'
        value = value.gsub(/\s/, '') # インデックス登録時の値に合わせて空白を除去しておく
      end
      highlight << /\A#{highlight_pattern(value)}\z/

      if merge_type == 'exact'
        qw = %Q["#{escape_query_string(value)}"]
      else
        qw = %Q[#{escape_query_string(value, true)}*]
      end
      qwords << %Q[#{field}:#{qw}]
    end

    # classification
    cls_params = {}
    (params[:classifications] || []).each do |cls_hash|
      cls_type_id = cls_hash['classification_type_id']
      cls_id = cls_hash['classification_id']
      next if cls_type_id.blank? || cls_id.blank?
      cls_params[cls_type_id] ||= []
      cls_params[cls_type_id] << cls_id
    end

    cls_params.each do |cls_type_id, cls_ids|
      cls_word = {}
      Classification.where(id: cls_ids).
        where(classification_type_id: cls_type_id).each do |cls|
          cls_word[cls.id.to_s] =
            "#{cls.classification_type.name}-#{cls.classification_identifier}" # Manifestationのsearchableブロックに合わせる
        end

      qws = cls_ids.map {|cls_id| cls_word[cls_id] || 'unknown' }
      if qws.size == 1
        qwords << "classification_sm:#{qws.first}"
      else
        qwords << "classification_sm:(#{qws.join(' OR ')})"
      end
    end
    # other attributes
    params[:other_identifier] = "#{params[:identifier_type]}-#{params[:other_identifier]}" unless params[:other_identifier].blank?
    [
      [:tag, 'tag_sm'],
      [:title, 'title_text', 'title_sm'],
      [:creator, 'creator_text', 'creator_sm'],
      [:contributor, 'contributor_text', 'contributor_sm'],
      [:isbn, 'isbn_sm'],
      [:issn, 'issn_sm'],
      [:ndc, 'ndc_sm'],
      [:edition_display_value, 'edition_display_value_sm'],
      [:volume_number_string, 'volume_number_string_sm'],
      [:issue_number_string, 'issue_number_string_sm'],
      [:serial_number_string, 'serial_number_string_sm'],
      [:lccn, 'lccn_s'],
      [:nbn, 'nbn_s'],
      [:publisher, 'publisher_text', 'publisher_sm'],
      [:item_identifier, 'item_identifier_sm'],
      [:except_query, nil],
      [:except_title, 'title_text', 'title_sm'],
      [:except_creator, 'creator_text', 'creator_sm'],
      [:except_publisher, 'publisher_text', 'publisher_sm'],
      [:identifier, 'identifier_sm'],
      [:other_identifier, 'other_identifier_sm']
    ].each do |key, field, onechar_field|
      next if special_match.include?(key)

      value = params[key]
      next if value.blank?

      qcs = []
      qws = []
      hls = []

      merge_type = params[:"#{key}_merge"]
      flg = /\Aexcept_/ =~ key.to_s ? '-' : ''
      each_query_word(value) do |word|
        hls << word if flg.blank?
        if word.size == 1 && onechar_field
          # 1文字だけの検索語を部分一致とみなす
          qcs << "#{flg}*#{word}*"
        else
          qws << "#{flg}#{word}"
        end
      end

      qw = []
      [
        [qcs, onechar_field || field],
        [qws, field],
      ].each do |q, f|
        next if q.blank?

        tag = f ? "#{f}:" : ''
        if q.size == 1
          qw << "#{tag}#{q.first}"
        elsif merge_type == 'any'
          qw << "#{tag}(#{q.join(' OR ')})"
        else
          qw << "#{tag}(#{q.join(' AND ')})"
        end
      end
      qwords.push qw.join(' AND ')

      if (key == :title || key == :creator) &&
          flg != '-' && hls.present?
        highlight.concat hls.map {|t| /#{highlight_pattern(t)}/ }
      end
    end

    # range
    [
      [:number_of_pages_at_least, :number_of_pages_at_most,
        :num_range_query, 'number_of_pages'],
      [:pub_date_from, :pub_date_to,
        :date_range_query, 'pub_date'],
      [:acquired_from, :acquired_to,
        :date_range_query, 'acquired_at'],
      [:removed_from, :removed_to,
        :date_range_query, 'removed_at'],
    ].each do |p1, p2, conv_method, field_base|
      next unless params[p1] || params[p2]
      q = __send__(conv_method, field_base, params[p1], params[p2])
      qwords << q if q
    end

    # 詳細検索からの資料区分 ファセット選択時は無効とする
    if params[:manifestation_types].present? && params[:manifestation_type].blank?
      types_ary = []
      manifestation_types = params[:manifestation_types]
      manifestation_types.each_key do |key|
        manifestation_type = ManifestationType.find(key) rescue nil
        types_ary << manifestation_type.name if manifestation_type.present?
      end
      qwords << "manifestation_type_sm:(" + types_ary.join(" OR ") + ")" if types_ary.present?
    end

    # merge basic and advanced
    op = SystemConfiguration.get("advanced_search.use_and") ? 'AND' : 'OR'
    [qwords.join(" #{op} "), highlight]
  end

  def highlight_pattern(str)
    str = $2 if /\A(['"])(.*)\1\z/ =~ str
    str.split(/\s+/).map {|s| Regexp.quote(s) }.join('(?>\\s+)')
  end

  # solr searchのためのfilter指定を構成する
  # TODO: このメソッドをfactoryに移動する
  def make_query_filter(options)
    with = []
    without = []

    #
    # params['mode']に関係なく設定するフィルタ
    #

    with << [
      :required_role_id, :less_than_or_equal_to,
      (current_user.try(:role) || Role.default_role).id
    ]

    if @removed
      with << [:has_removed, :equal_to, true]
    else
      if !params[:missing_issue] && 
        (@all_manifestations.blank? or !@all_manifestations == true) &&
        !SystemConfiguration.get("manifestation.show_all") 
        without << [:non_searchable, :equal_to, true]
      end
    end
    without << [:hide, :equal_to, true]

    without << [:id, :equal_to, @binder.manifestation.id] if @binder

    unless params[:with_periodical_item]
      unless @binder
        with << [:periodical, :equal_to, false] if options[:add_mode].blank? and @series_statement.blank? and @basket.blank?
      end
    end
    with << [:periodical_master, :equal_to, false] if options[:add_mode] 
    return [with, without] if options[:add_mode]

    #
    # params['mode']が'add'でないときだけ設定するフィルタ
    #
    with << [:reservable, :equal_to, @reservable] unless @reservable.nil?
    with << [:periodical_master, :equal_to, false] if @series_statement or @basket
    with << [:carrier_type, :equal_to, params[:carrier_type]] if params[:carrier_type]
    with << [:missing_issue, :equal_to, params[:missing_issue]] if params[:missing_issue]
    with << [:in_process, :equal_to, @in_process] unless @in_process.nil?
    with << [:manifestation_type, :equal_to, params[:manifestation_type]] if params[:manifestation_type]
    with << [:circulation_status_in_process, :equal_to, params[:circulation_status_in_process]] if params[:circulation_status_in_process]
    with << [:circulation_status_in_factory, :equal_to, params[:circulation_status_in_factory]] if params[:circulation_status_in_factory]
    with << [:no_item, :equal_to, params[:no_item]] if params[:no_item]

    [
      [:publisher_ids, @agent],
      [:creator_ids, @index_agent[:creator]],
      [:contributor_ids, @index_agent[:contributor]],
      [:publisher_ids, @index_agent[:publisher]],
      [:original_manifestation_ids, @manifestation],
      [:subject_ids, @subject],
      [:bookbinder_id, @binder],
      [:series_statement_id, @series_statement],
    ].each do |field, record|
      with << [field, :equal_to, record.id] if record
    end

    if params[:subject]
      subject = Subject.where(term: params[:subject]).first
      with << [:subject, :equal_to, subject.try(:term)]
    end

    unless params[:library].blank?
      params[:library].split.uniq.each do |library|
        with << [:library, :equal_to, library]
      end
    end

    unless params[:language].blank?
      params[:language].compact.uniq.each do |language|
        with << [:language, :equal_to, language]
      end
    end

    if defined?(EnjuTrunkTheme)
      if @theme
        with << [:id, :any_of, @theme.manifestations.collect(&:id)]
      end
    end

    if @basket
      with << [:id, :any_of, @basket.manifestations.collect(&:id)]
    end

    [with, without]
  end

  def search_result_order(sort_by, order)
    sort = {}

    # TODO: ページ数や大きさでの並べ替え
    case sort_by
    when 'title'
      sort[:sort_by] = 'sort_title'
      sort[:order] = 'asc'
    when 'pub_date'
      sort[:sort_by] = 'date_of_publication'
      sort[:order] = 'desc'
    when 'carrier_type'
      sort[:sort_by] = 'carrier_type'
      sort[:order] = 'desc'
    when 'author'
      sort[:sort_by] = 'author'
      sort[:order] = 'asc'
    else
      # デフォルトの並び方
      sort[:sort_by] = 'created_at'
      sort[:order] = 'desc'
    end

    if order == 'asc'
      sort[:order] = 'asc'
    elsif order == 'desc'
      sort[:order] = 'desc'
    end

    sort
  end

  def render_mode(mode)
    case mode
    when 'barcode'
      barcode = Barby::QrCode.new(@manifestation.id)
      send_data(barcode.to_svg, :disposition => 'inline', :type => 'image/svg+xml')
    when 'holding'
      render :partial => 'manifestations/show_holding', :locals => {:manifestation => @manifestation}
    when 'tag_edit'
      if defined?(EnjuBookmark)
        render :partial => 'manifestations/tag_edit', :locals => {:manifestation => @manifestation}
      end
    when 'tag_list'
      if defined?(EnjuBookmark)
        render :partial => 'manifestations/tag_list', :locals => {:manifestation => @manifestation}
      end
    when 'show_index'
      render :partial => 'manifestations/show_index', :locals => {:manifestation => @manifestation}
    when 'show_creators'
      render :partial => 'manifestations/show_creators', :locals => {:manifestation => @manifestation}
    when 'show_all_creators'
      render :partial => 'manifestations/show_creators', :locals => {:manifestation => @manifestation}
    when 'pickup'
      render :partial => 'manifestations/pickup', :locals => {:manifestation => @manifestation}
    when 'calil_list'
      render :partial => 'manifestations/calil_list', :locals => {:manifestation => @manifestation}
    else
      false
    end
  end

  def prepare_options
    @carrier_types = CarrierType.all
    @sub_carrier_types = SubCarrierType.all
    @manifestation_types = ManifestationType.all
    @roles = Role.all
    @languages = Language.all_cache
    @language_types = LanguageType.all
    @countries = Country.all
    @frequencies = Frequency.all
    @nii_types = NiiType.all if defined?(NiiType)
    @create_types = CreateType.find(:all, :select => "id, name, display_name")
    @realize_types = RealizeType.find(:all, :select => "id, name, display_name")
    @produce_types = ProduceType.find(:all, :select => "id, name, display_name")
    @default_language = Language.where(:iso_639_1 => @locale).first
    @title_types = TitleType.find(:all, :select => "id, display_name", :order => "position")
#TODO starts
    @work_manifestation = Manifestation.new
    @work_manifestation.work_has_titles = @manifestation.work_has_titles
    @work_has_languages = @manifestation.work_has_languages
    @work_has_languages << WorkHasLanguage.new if @work_has_languages.blank?
#TODO end
    @numberings = Numbering.get_manifestation_numbering
    if SystemConfiguration.get('manifestation.use_identifiers')
      @identifier_types = IdentifierType.find(:all, :select => "id, display_name", :order => "position") || []
    end
    @use_licenses = UseLicense.all
    @classification_types = ClassificationType.order("position").all

    # 書誌と所蔵を１：１で管理　編集のためのデータを準備する
    if SystemConfiguration.get("manifestation.has_one_item") == true
      @libraries = Library.real
      @libraries.delete_if {|l| l.shelves.empty?}
      if @manifestation.items.present?
        @item = SystemConfiguration.get('manifestation.manage_item_rank') ? @manifestation.items.sort_rank.first : @manifestation.items.first
        @library = @item.shelf.library rescue nil
      else
        @item = Item.new
        @library = Library.real.first(:order => :position, :include => :shelves)
      end
      @shelf_categories = Shelf.try(:categories) rescue nil
      if @shelf_categories
        @shelves = []
        @shelves << @item.shelf if @item
      else
        @shelves = @library.shelves
      end
      @checkout_types = CheckoutType.all
      @accept_types = AcceptType.all
      @circulation_statuses = CirculationStatus.all
      @circulation_statuses.reject!{|cs| cs.name == "Removed"}
      @retention_periods = RetentionPeriod.all
      @bookstores = Bookstore.all
      @use_restrictions = UseRestriction.available
      @roles = Role.all
      @claim_types = ClaimType.all
      @item_numberings = []
      Numbering.where(:numbering_type => 'item').each do |numbering|
        @item_numberings << Manifestation::SELECT2_OBJ.new(numbering.name, numbering.name, numbering.display_name)
      end
      @use_restriction_id = @item.use_restriction.present? ? @item.use_restriction.id : nil
      if SystemConfiguration.get('manifestation.use_item_has_operator')
        @countoperators = ItemHasOperator.count(:conditions => ["item_id = ?", @item])
        if @item.item_has_operators.blank?
          @item.item_has_operators << ItemHasOperator.new(:operated_at => Date.today.to_date, :library_id => @library)
        end
      end
    end

  end

  def save_search_history(query, offset = 0, total = 0, user = nil)
    check_dsbl if LibraryGroup.site_config.use_dsbl
    if SystemConfiguration.get("write_search_log_to_file")
      write_search_log(query, total, user)
    else
      SearchHistory.create(:query => query, :user => user, :start_record => offset + 1, :maximum_records => nil, :number_of_records => total)
    end
  end

  def write_search_log(query, total, user)
    SEARCH_LOGGER.info "#{Time.zone.now}\t#{query}\t#{total}\t#{user.try(:username)}\t#{params[:format]}"
  end

  def set_reserve_user
    if current_user.try(:has_role?, 'Librarian') && params[:user_id]
      @reserve_user = User.find(params[:user_id]) rescue current_user
    else
      @reserve_user = current_user
    end
  end

  def set_reservable
    case params[:reservable].to_s
    when 'true'
      @reservable = true
    when 'false'
      @reservable = false
    else
      @reservable = nil
    end
  end

  def set_in_process
    case params[:in_process].to_s
    when 'true'
      @in_process = true
    when 'false'
      @in_process = false
    else
      @in_process = nil
    end
  end

  # "*_sm"フィールドに対する自然数の範囲条件を指定する
  # solrクエリー文字列を返す
  def num_range_query(field_base, num_from, num_to)
    n1 = n2 = nil
    num_regex = /\A0*[1-9]\d*/

    n1 = $&.to_i if num_regex =~ num_from
    n2 = $&.to_i if num_regex =~ num_to

    n1, n2 = n2, n1 if n1 && n2 && n1 > n2

    block = proc {|n| n < 1 }
    r_begin = (n1.nil? || block.call(n1)) ? '*' : n1.to_s
    r_end   = (n2.nil? || block.call(n2)) ? '*' : n2.to_s

    return nil if r_begin == '*' && r_end == '*'
    "#{field_base}_sm:[#{r_begin} TO #{r_end}]"
  end

  # "*_sm"フィールドに対する日時範囲条件を指定する
  # solrクエリー文字列を返す。
  def date_range_query(field_base, date_from, date_to)
    r_begin, r_end = construct_time_range(date_from, date_to)

    return nil if r_begin.blank? && r_end.blank?
    "#{field_base}_sm:[#{r_begin.try(:iso8601) || '*'} TO #{r_end.try(:iso8601) || '*'}]"
  end

  def next_page_number_for_oai_search
    return 1 unless params[:resumptionToken]

    current_token = get_resumption_token(params[:resumptionToken])
    unless current_token
      @oai[:errors] << 'badResumptionToken'
      return 1
    end

    per_page = 200 # OAI-PMHのデフォルトの件数
    (current_token[:cursor].to_i + per_page).div(per_page) + 1
  end

  def total_search_result_count(result)
    max_count = SystemConfiguration.get("max_number_of_results")
    total = result.total
    total > max_count ? max_count : total
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
          (SystemConfiguration.get('manifestation.isbn_unique') &&
            params[:isbn].present? && params[:isbn] !~ /\*/) ||
              (params[:identifier].present? && params[:identifier] !~ /\*/)
        search_opts[:direct_mode] = true unless params[:binding_items_flg] 
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
    if search_opts[:csv_mode]
      per_page = 65534
    elsif per_pages
      per_page = per_pages[0]
    end
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

  # indexアクションにおける検索関係のセッションデータを更新する。
  #
  #  * search_opts - 検索条件
  #  * search_container - 検索用のコンテナ(factory.new_searchで得られるもの)
  def update_search_sessions(search_opts, search_container)
    return unless search_opts[:index] == :local # FIXME: 非local検索のときにも動作するようにする

    search = search_container[:session]

    if session[:search_params]
      unless search.query.to_params == session[:search_params]
        clear_search_sessions
      end
    else
      clear_search_sessions
      session[:params] = params
      session[:search_params] = search.query.to_params
      session[:query] = search_opts[:solr_query_mode] ? @solr_query : @query
    end

    unless session[:manifestation_ids]
      # FIXME?
      # session[:manifestation_ids]は検索結果の書誌情報を次々と見るのに使われている
      # (manifestations/index→manifestations/show→manifestations/show→...)。
      # よって文献とその他を分ける場合には、このデータも分けて取りまわす必要があるはず。
      manifestation_ids = search.
        execute.raw_results.map {|r| r.primary_key.to_i }
      session[:manifestation_ids] = manifestation_ids
    end
  end

  # indexアクションにおけるOAI GetRecordへの応答出力を行う。
  # renderしたらtrueを返す。
  #
  #  * search_opts - 検索条件
  def do_oai_get_record_process(search_opts)
    unless search_opts[:oai_mode] &&
        params[:verb] == 'GetRecord' && params[:identifier]
      return false
    end

    begin
      @manifestation = Manifestation.find_by_oai_identifier(params[:identifier])
      render :template => 'manifestations/show', :formats => :oai, :layout => false
    rescue ActiveRecord::RecordNotFound
      @oai[:errors] << "idDoesNotExist"
      render :template => 'manifestations/index', :formats => :oai, :layout => false
    end

    true
  end
  #
  # indexアクションにおける直接参照への応答出力を行う。
  # renderしたらtrueを返す。
  #
  #  * search_opts - 検索条件
  def do_direct_mode_process(search_opts)
    return false unless search_opts[:direct_mode]

    manifestation = nil

    if params[:item_identifier].present?
      is = Item.where(:item_identifier => params[:item_identifier])
      manifestation = is.first.manifestation if is.size == 1
    end

    if SystemConfiguration.get("manifestation.isbn_unique") &&
        params[:isbn].present?
      ms = Manifestation.where(:isbn => params[:isbn])
      manifestation = ms.first if ms.size == 1
    end

    if params[:identifier].present?
      manifestation = Manifestation.where(:identifier => params[:identifier]).try(:first)
    end

    if manifestation
      unless params[:binding_items_flg]
        redirect_to manifestation
        return true
      end
    end

    false
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

  # indexアクションにおけるタグクラウド用の出力をする。
  # renderしたらtrueを返す。
  #
  #  * search_opts - 検索条件
  def do_tag_cloud_process(search_opts)
    unless search_opts[:tag_cloud_mode] && session[:manifestation_ids]
      return false
    end

    bookmark_ids = Bookmark.where(:manifestation_id => session[:manifestation_ids]).limit(1000).select(:id).collect(&:id)
    @tags = Tag.bookmarked(bookmark_ids)
    render :partial => 'manifestations/tag_cloud'
    #session[:manifestation_ids] = nil

    true
  end

  # 
  # create classification vaules
  # 
  def create_classification_values(add_classifications)
    classifications = []
    add_classifications.each do |add_classification|
      next if add_classification[:classification_id].blank?
      classification = Classification.where(:id => add_classification[:classification_id]).first
      classifications << classification if classification.present?
    end
    return classifications
  end

  # 
  # get classification vaules
  # 
  def get_classification_values(manifestation)
    classifications = []
    manifestation_has_classifications = manifestation.manifestation_has_classifications.order(:position)
    if manifestation_has_classifications.present?
      manifestation_has_classifications.each do |manifestation_has_classification|
        classifications << {:classification_type_id => manifestation_has_classification.classification.classification_type_id,
                            :classification_id => manifestation_has_classification.classification_id}
      end
    else
      classifications << {}
    end
    return classifications
  end

end


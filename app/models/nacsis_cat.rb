# encoding: utf-8

class NacsisCat
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :record

  class Error < StandardError
    def initialize(raw_result, message = nil)
      super(message)
      @raw_result = raw_result
    end
    attr_reader :raw_result
  end
  class ClientError < Error; end
  class ServerError < Error; end
  class UnknownError < Error; end

  class NetworkError < StandardError
    def initialize(orig_ex, message = nil)
      message ||= orig_ex.message
      super(message)
      @original_exception = orig_ex
    end
    attr_reader :original_exception
  end

  class ResultArray < Array
    def initialize(search_result)
      @raw_result = search_result
      @total = @raw_result.try(:[], 'total') || 0

      if @raw_result.try(:[], 'records')
        @raw_result['records'].each do |record|
          self << NacsisCat.new(:record => record)
        end
      end
    end
    attr_reader :raw_result, :total
  end

  class << self
    # NACSIS-CAT検索を実行する。検索結果はNacsisCatオブジェクトの配列で返す。
    # 検索条件は引数で指定する。サポートしている形式は以下の通り。
    #  * :dbs => [...] - 検索対象のDB名リスト: :book(一般書誌)、:serial(雑誌書誌)、:bhold(一般所蔵)、:shold(雑誌所蔵)、:all(:bookと:serialからの横断検索)
    #  * :opts => {...} - DBに対するオプション(ページ指定): 指定例: {:book => {:page => 2, :per_page => 30}, :serial => {...}}
    #  * :id => '...' - NACSIS-CATの書誌IDにより検索する(***)
    #  * :bid => '...' - NACSIS-CATの書蔵IDにより検索する(***)
    #  * :isbn => '...' - ISBN(ISBNKEY)により検索する(***)
    #  * :issn => '...' - ISSN(ISSNKEY)により検索する(***)
    #  * :nbn => '...' - NBN(NBN)により検索する(***)#
    #  * :query => '...' - 一般検索語により検索する(*)
    #  * :title => [...] - 書名(_TITLE_)により検索する(*)
    #  * :author => [...] - 著者名(_AUTH_)により検索する(*)
    #  * :publisher => [...] - 出版者名(PUBLKEY)により検索する(*)
    #  * :subject => [...] - 件名(SHKEY)により検索する(*)
    #  * :except => {...} - 否定条件により検索する(*)(**)
    #
    # (*) :dbsが:bookまたは:serialのときのみ機能する
    # (**) :query、:title、:author、:publisher、:subjectの否定形に対応
    # (***) 配列で指定することもでき、その場合は指定した複数キーによるOR検索となる
    #
    # :dbsには基本的に複数のDBを指定する。
    # 検索結果は {:book => aResultArray, ...} のような形となる。
    # なお、複数DBを指定した場合、すべてのDBに対して同じ条件で検索を行う。
    # このため、たとえば :dbs => [:book, :bhold] のように
    # まったく違う種類のDBを指定してもうまく動作しない。
    def search(*args)
      options = args.extract_options!
      options.assert_valid_keys(
        :dbs, :opts,
        :id, :isbn, :issn, :nbn,
        :query, :title, :author, :publisher, :subject, :except)
      if options[:except]
        options[:except].assert_valid_keys(
          :query, :title, :author, :publisher, :subject)
      end

      dbs = options.delete(:dbs) || [:book]
      db_opts = options.delete(:opts) || {}

      if options.blank? || options.keys == [:except]
        return {}.tap do |h|
          dbs.each {|db| h[db] = ResultArray.new(nil) }
        end
      end

      if (dbs.include?(:shold) || dbs.include?(:bhold)) &&
          options.include?(:id)
        options[:bid] = options.delete(:id)
      end
      query = build_query(options)
      search_by_gateway(dbs: dbs, opts: db_opts, query: query)
    end

    # 指定されたNCIDによりNACSIS-CAT検索を行い、得られた情報からManifestationを作成する
    #
    # * ncid - NCID
    # * book_types - 書籍の書誌種別(ManifestationType)の配列
    #                (NOTE: バッチ時の外部キャッシュ用で和書・洋書にあたるレコードを与える)
    # * nacsis_cat - NacsisCat.searchを既に実行している場合、取得したNacsisCatモデルを設定する
    def create_manifestation_from_ncid(ncid, book_types = ManifestationType.book.all, nacsis_cat = nil)
      raise ArgumentError if ncid.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:book], id: ncid)
        nacsis_cat = result[:book].first
      end
      create_manifestation_from_nacsis_cat(nacsis_cat, book_types)
    end

    # 指定されたNCIDによりNACSIS-CAT検索を行い、得られた情報からSeriesStatementを作成する。
    #
    # * ncid - NCID
    # * book_types - 書籍の書誌種別(ManifestationType)の配列
    #                (NOTE: バッチ時の外部キャッシュ用で和雑誌・洋雑誌にあたるレコードを与える)
    # * nacsis_cat - NacsisCat.searchを既に実行している場合、取得したNacsisCatモデルを設定する
    def create_series_statement_from_ncid(ncid, book_types = ManifestationType.series.all, nacsis_cat = nil)
      raise ArgumentError if ncid.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:serial], id: ncid)
        nacsis_cat = result[:serial].first
      end
      create_series_with_relation_from_nacsis_cat(nacsis_cat, book_types)
    end

    # 指定されたNCIDリストによりNACSIS-CAT検索を行い、得られた情報からManifestation, SeriesStatement を作成する
    #
    # * ncids - NCIDのリスト
    # * opts
    #   * nacsis_batch_size - 一度に検索するNCID数
    def batch_create_from_ncid(ncids, opts = {}, &block)
      nacsis_batch_size = opts[:nacsis_batch_size] || 50

      ncids.each_slice(nacsis_batch_size) do |ids|
        result = NacsisCat.search(dbs: [:all], id: ids)
        result[:all].each do |nacsis_cat|
          if nacsis_cat.serial?
            created_record =
              create_series_statement_from_ncid(nacsis_cat.ncid, ManifestationType.series.all, nacsis_cat)
          else
            created_record =
              create_manifestation_from_ncid(nacsis_cat.ncid, ManifestationType.book.all, nacsis_cat)
          end
          block.call(created_record) if block
        end
      end
    end

    # NACSISへ情報の登録・更新・削除を行い、結果データ(cat_container)を返却する
    #
    # * id - 編集対象のモデルの id
    #        BHOLD  : Item.id
    #        SHOLD  : Item.id
    #        BOOK   : Manifestation.id
    #        SERIAL : SeriesStatement.id
    #
    # * db_type - NACSISへの編集対象となるDB名
    #             図書所蔵 : 'BHOLD'
    #             雑誌所蔵 : 'SHOLD'
    #             図書書誌 : 'BOOK'
    #             雑誌書誌 : 'SERIAL'
    #
    # * command - NACSISへ送信するコマンド名
    #             登録 : 'insert'
    #             更新 : 'update'
    #             削除 : 'delete' (BOOK,SERIALの場合は実行不可)
    #
    def upload_info_to_nacsis(id, db_type, command)
      return {} unless check_upload_params(id, db_type, command)

      req_query = {}

      case db_type
      when 'BHOLD','SHOLD'
        @item = Item.find(id)
        req_query[:query] = hold_query(command, db_type)
        result_id = @item.nacsis_identifier

      when 'BOOK'
        @manifestation = Manifestation.find(id)
        if @manifestation.series_statement.try(:root_manifestation)
          @manifestation = @manifestation.series_statement.root_manifestation
        end
        req_query[:query] = book_query(command)
        result_id = @manifestation.nacsis_identifier

      when 'SERIAL'
        @series_statement = SeriesStatement.find(id)
        @manifestation = @series_statement.root_manifestation
        req_query[:query] = serial_query(command)
        result_id = @series_statement.nacsis_series_statementid

      end

      return {} unless req_query[:query]

      req_query[:command] = command
      req_query[:db_type] = db_type
      req_query[:db_names] = [db_type]

      result_info = {}
      result_info = http_post_value(gateway_upload_cat_url, {:cat_container => req_query})
      cat_container = result_info['cat_container']

      return {} unless cat_container

      if cat_container['catp_code'] == '200'
        result_record = cat_container['result_records'].try(:first)
        case db_type
        when 'BHOLD','SHOLD'
          if command == 'insert'
            result_record = db_type == 'BHOLD' ? result_record['bhold_info'] : result_record['shold_info']
            result_id = result_record['hold_id']
          end
          hold_id = command == 'delete' ? nil : result_id
          @item.nacsis_identifier = hold_id
          @item.save!
        when 'BOOK'
          result_id = result_record['book_info']['bibliog_id']
          @manifestation.nacsis_identifier = result_id
          @manifestation.save!
        when 'SERIAL'
          result_id = result_record['serial_info']['bibliog_id']
          @series_statement.nacsis_series_statementid = result_id
          @series_statement.save!
        end
      end
      { :return_code => cat_container['catp_code'],
        :return_phrase => cat_container['catp_phrase'],
        :result_id => result_id }
    end

    # 指定されたNBN(全国書誌番号)によりNACSIS-CAT検索を行い、得られた情報からManifestationを作成する
    def create_manifestation_from_nbn(nbn, book_types = ManifestationType.book.all, nacsis_cat = nil)
      raise ArgumentError if nbn.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:book], nbn: nbn)
        nacsis_cat = result[:book].first
      end
      create_manifestation_from_nacsis_cat(nacsis_cat, book_types)
    end

    # 指定されたNBN(全国書誌番号)によりNACSIS-CAT検索を行い、得られた情報からSeriesStatementを作成する。
    def create_series_statement_from_nbn(nbn, book_types = ManifestationType.series.all, nacsis_cat = nil)
      raise ArgumentError if nbn.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:serial], nbn: nbn)
        nacsis_cat = result[:serial].first
      end
      create_series_with_relation_from_nacsis_cat(nacsis_cat, book_types)
    end

    # 指定されたISBNによりNACSIS-CAT検索を行い、得られた情報からManifestationを作成する
    def create_manifestation_from_isbn(isbn, book_types = ManifestationType.book.all, nacsis_cat = nil)
      raise ArgumentError if isbn.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:book], isbn: isbn) #複数あるかも
        nacsis_cat = result[:book].first
      end
      create_manifestation_from_nacsis_cat(nacsis_cat, book_types)
    end
    # 指定されたISBNによりNACSIS-CAT検索を行い、得られた情報からSeriesStatementを作成する。
    def create_series_statement_from_isbn(isbn, book_types = ManifestationType.series.all, nacsis_cat = nil)
      raise ArgumentError if isbn.blank?
      if nacsis_cat.nil?
        result = NacsisCat.search(dbs: [:serial], isbn: isbn) #複数あるかも
        nacsis_cat = result[:serial].first
      end
      create_series_with_relation_from_nacsis_cat(nacsis_cat, book_types)
    end

    private

      DB_KEY = {
        query: ['_TITLE_', '_AUTH_', 'PUBLKEY', 'SHKEY'],
        title: '_TITLE_',
        author: '_AUTH_',
        publisher: 'PUBLKEY',
        subject: 'SHKEY',
        id: 'ID',
        bid: 'BID',
        isbn: 'ISBNKEY',
        issn: 'ISSNKEY',
        nbn: 'NBN',
      }
      def build_query(cond, inverse = false)
        if inverse
          op = 'OR'
        else
          op = 'AND'
        end

        except = cond.delete(:except)
        segments = cond.map do |key, value|
          case key
          when :id, :bid, :isbn, :issn, :nbn
            rpn_concat(
              'OR',
              [value].flatten.map {|v| rpn_seg(DB_KEY[key], v) })

          when :title, :author, :publisher, :subject
            rpn_concat(
              op,
              [value].flatten.map {|v| rpn_seg(DB_KEY[key], v) })

          when :query
            rpn_concat(
              op,
              [value].flatten.map do |v|
                rpn_concat(
                  'OR', DB_KEY[:query].map {|k| rpn_seg(k, v) })
              end
            )
          end
        end

        if except.blank?
          rpn_concat(op, segments)
        else
          rpn_concat(
            'AND-NOT', [
              rpn_concat(op, segments),
              build_query(except, true)
            ])
        end
      end

      def rpn_concat(op, cond)
        cond.inject([]) do |ary, c|
          f = ary.empty?
          ary << c
          ary << op unless f
          ary
        end.join(' ')
      end

      def rpn_seg(key, value)
        %Q!#{key}="#{value.to_s.gsub(/[\\"]/, '\\\1')}"!
      end

      def search_by_gateway(options)
        # db_type = db_names = nil

        key_to_db = {
          all: '_ALL_',
          book: 'BOOK',
          serial: 'SERIAL',
          bhold: 'BHOLD',
          shold: 'SHOLD',
        }

        dbs = options[:dbs].map do |key|
          db = key_to_db[key]
          raise ArgumentError, "unknwon db: #{key}" unless db
          db
        end

        db_opts = {}
        options[:opts].each do |key, v|
          db = key_to_db[key]
          next unless db
          next unless dbs.include?(db)
          db_opts[db] = v
        end

        q = {}
        q[:db] = dbs
        q[:opts] = db_opts if db_opts.present?
        q[:query] = options[:query]

        url = "#{gateway_search_url}?#{q.to_query}"
        begin
          return_value = http_get_value(url)
        rescue SocketError, SystemCallError => ex
          raise NetworkError.new(ex)
        end

        case return_value['status']
        when 'success'
          ex = nil
        when 'user-error'
          ex = ClientError
        when 'gateway-error'
          ex = ServerError
        when 'server-error'
          ex = ServerError
        else
          ex = UnknownError
        end
        if ex
          raise ex.new(return_value, return_value['phrase'])
        end

        ret = {}
        db_to_key = key_to_db.invert
        return_value['results'].each_pair do |db, result|
          key = db_to_key[db]
          ret[key] = ResultArray.new(result)
        end

        ret
      end

      def gateway_config
        NACSIS_CLIENT_CONFIG[Rails.env]['gw_account']
      end

      def gateway_search_url
        url = gateway_config['gw_url']
        url.sub(%r{/*\z}, '/') + 'records'
      end

      def http_get_value(url)
        uri = URI(url)

        opts = {}
        if uri.scheme == 'https'
          opts[:use_ssl] =  true

          if gateway_config.include?('ssl_verify') &&
              gateway_config['ssl_verify'] == false
            # config/nacsis_client.ymlで'ssl_verify': falseのとき
            opts[:verify_mode] = OpenSSL::SSL::VERIFY_NONE
          else
            opts[:verify_mode] = OpenSSL::SSL::VERIFY_PEER
          end
        end

        resp = Net::HTTP.start(uri.host, uri.port, opts) do |h|
          h.get(uri.request_uri)
        end

        JSON.parse(resp.body)
      end

      def check_upload_params(id, db_type, command)
        return unless id
        return unless (['BHOLD','SHOLD','BOOK','SERIAL'].include?(db_type))
        return unless (['insert','update','delete'].include?(command))
        case db_type
        when 'BOOK','SERIAL'
          return if command == 'delete'
        end
        return true
      end

      def hold_query(command, db_type)
        return unless @item
        return @item.nacsis_identifier if command == 'delete'

        query_field = command == 'update' ? ["ID=#{@item.nacsis_identifier}"] : []
        query_field += [
          "FANO=#{gateway_config['federation_id']}",
          "LOC=#{@item.shelf.library.nacsis_location_code}",
        ]

        i = 0
        @item.manifestation.subjects.each do |subject|
          unless subject.subject_type.note == 'for nacsis data'
            i += 1
            query_field += [
              "LTR=#{subject.term}"
            ]
          end
          break if i >= 4
        end

        if db_type == 'BHOLD'
          if @item.manifestation.nacsis_identifier
            query_field += ["BID=#{@item.manifestation.nacsis_identifier}"]
          else
            query_field += ["BID=#{@item.manifestation.series_statement.nacsis_series_statementid}"]
          end
          @item.manifestation.items.each do |item|
            query_field += [
              '<HOLD>',
              "VOL=#{item.manifestation.vol_string}",
              "CLN=#{item.call_number}",
              "RGTN=#{item.item_identifier}",
              "CPYR=#{item.manifestation.date_of_publication.try(:year)}",
              "LDF=#{item.note}",
              "CPYNT=#{item.manifestation.note}",
              '</HOLD>'
            ]
          end
        else
          cont = '+' if @item.manifestation.series_statement.publication_status.try(:name) == 'c'
          query_field += [
            "BID=#{@item.manifestation.series_statement.nacsis_series_statementid}",
            "HLYR=#{shold_hl_info[:HLYR]}",
            "HLV=#{shold_hl_info[:HLV]}",
            "CONT=#{cont}",
            "CLN=#{@item.manifestation.items.pluck(:call_number).reject{|c| c.blank?}.join("||")}",
            "LDF=#{@item.manifestation.items.pluck(:note).reject{|n| n.blank?}.join("||")}",
            "CPYNT=#{@item.manifestation.note}"
          ]
        end
        query_field.join("\n")
      end

      def shold_hl_info
        hl_info = {}
        hlyr = @item.manifestation.series_statement.manifestations.pluck(:date_of_publication_string).reject{|c| c.blank?}.sort
        if hlyr.present?
          hl_info[:HLYR] = hlyr[0] + '-' + hlyr[hlyr.count - 1]
        end
        if hl_info[:HLYR].blank?
          hl_info[:HLYR] = '*'
        end
        hl_info[:HLV] = @item.manifestation.series_statement.manifestations.pluck(:volume_number_string).reject{|c| c.blank?}.join(",")
        if hl_info[:HLV].blank?
          hl_info[:HLV] = '*'
        end
        hl_info
      end

      def book_query(command)
        return unless @manifestation
        query_field = command == 'update' ? ["ID=#{@manifestation.nacsis_identifier}"] : []

        # Common field
        query_field += common_field

        # Book field
        query_field += book_field

        query_field.join("\n")
      end

      def serial_query(command)
        return unless @series_statement && @manifestation
        query_field = command == 'update' ? ["ID=#{@series_statement.nacsis_series_statementid}"] : []

        # Common field
        query_field += common_field

        # Serial field
        query_field += serial_field

        query_field.join("\n")
      end

      def common_field

        source = @manifestation.catalog.nacsis_identifier if @manifestation.catalog
        if source == 'NACSIS' || source == 'NDL' || source.nil?
          source = 'ORG'
        end

        repro = 'c' if @manifestation.original == true

        field = [
          "MARCID=", # SOURCE=ORG 以外の場合必須
          "SOURCE=#{source}", # [Required]
          "ISSN=#{@manifestation.issn}",
          "LCCN=#{@manifestation.lccn}",
          "GPON=#{get_identifier_number('gpon')}",
          "GMD=#{@manifestation.carrier_type.try(:nacsis_identifier)}",
          "SMD=#{@manifestation.sub_carrier_type.try(:nacsis_identifier)}",
          "CNTRY=#{@manifestation.country_of_publication.marc21}",
          "REPRO=#{repro}",
          "TTLL=#{get_nacsis_language('title')}",
          "TXTL=#{get_nacsis_language('body')}",
          "ORGL=#{get_nacsis_language('original')}",
          "ED=#{@manifestation.edition_display_value}",
          "NOTE=#{@manifestation.note}"
        ]

        # YEAR Group [Required]
        field += year_group

        # TR Group [Required]
        field += tr_group

        # VT Group Repeat:16
        field += vt_group

        # PUB Group [Required] Repeat:4
        field += pub_group

        # PHYS Group
        field += phys_group

        # AL Group Repeat:24
        field += al_group

        # SH Group Repeat:24
        field += sh_group

        field
      end

      def book_field

        field = []

        get_identifier_numbers('ndlcn').each do |number|
          field << "NDLCN=#{number}" # Repeat:255
        end

        get_identifier_other_numbers.each do |other_number|
          field << "OTHN=#{other_number[0, 23]}" # Repeat:255
        end

        nbn_array = @manifestation.nbn.try(:split, ',') || []
        nbn_array.each do |nbn_str|
          field <<  "NBN=#{nbn_str}" # Repeat:255
        end

        # VOLG Group
        field += volg_group

        # CW Group
        field += cw_group

        # PTBL Group
        field += ptbl_group

        # UTL Group Repeat:255
        field += utl_group

        # CLS Group Repeat:24
        field += cls_group

        field
      end

      def get_identifier_other_numbers
        return [] unless @manifestation
        other_numbers = []
        excluded_types = ['isbn','xisbn','issn','nbn','ndlcn','gpon','ndlpn','coden','ulpn']
        @manifestation.identifiers.each do |identifier|
          unless excluded_types.include?(identifier.identifier_type.name)
            other_numbers << "#{identifier.identifier_type.name}:#{identifier.body}"
          end
        end
        other_numbers
      end

      def serial_field
        vlyr = []
        @manifestation.manifestation_extexts.where(:name => 'VLYR').each do |extext|
          vlyr << extext.value
        end
        result = [
          "NDLPN=#{get_identifier_number('ndlpn')}",
          "CODEN=#{get_identifier_number('coden')}",
          "ULPN=#{get_identifier_number('ulpn')}",
          "PSTAT=#{@series_statement.publication_status.try(:name)}",
          "FREQ=#{@manifestation.frequency.try(:nii_code)}",
          "REGL=#{}",
          "TYPE=#{@manifestation.manifestation_type.try(:nacsis_identifier)}",
          "VLYR=#{vlyr[0]}",
          "VLYR=#{vlyr[1]}",
          "VLYR=#{vlyr[2]}",
          "VLYR=#{vlyr[3]}",
          "PRICE=#{@manifestation.price_string}"
        ]
        get_identifier_numbers('xissn').each do |xissn|
          result << "XISSN=#{xissn}"
        end
        result
      end

      def get_identifier_number(type_name)
        return unless @manifestation && type_name
        identifier_type = IdentifierType.where(:name => type_name).first
        if identifier_type
          identifier = @manifestation.identifiers.where('identifier_type_id' => identifier_type.id).first
        end
        identifier.try(:body)
      end

      def get_identifier_numbers(type_name)
        return [] unless @manifestation && type_name
        numbers = []
        identifier_type = IdentifierType.where(:name => type_name).first
        if identifier_type
          numbers = @manifestation.identifiers.where('identifier_type_id' => identifier_type.id).pluck(:body)
        end
        numbers
      end

      def volg_group # book only
        results = []
        identifier_type = IdentifierType.where(:name => 'isbn').first
        manifestations = @manifestation.series_statement.try(:manifestations)
        if manifestations
          manifestations.each do |manifestation|
            unless @manifestation.series_statement.root_manifestation == manifestation
              identifier = manifestation.identifiers.where(:identifier_type_id => identifier_type.id).first
              results += [
                '<VOLG>',
                "VOL=#{manifestation.edition_display_value}",
                "ISBN=#{identifier.try(:body)}",
                "PRICE=#{manifestation.price_string}",
                "XISBN=#{manifestation.wrong_isbn}",
                '</VOLG>'
              ]
            end
          end
        else
          identifier = @manifestation.identifiers.where(:identifier_type_id => identifier_type.id).first
          results = [
            '<VOLG>',
            "VOL=#{@manifestation.edition_display_value}",
            "ISBN=#{identifier.try(:body)}",
            "PRICE=#{@manifestation.price_string}",
            "XISBN=#{@manifestation.wrong_isbn}",
            '</VOLG>'
          ]
        end
        results
      end

      def year_group
        [
          '<YEAR>',
          "YEAR1=#{@manifestation.pub_date.try(:[], 0, 4)}",
          "YEAR2=#{@manifestation.dis_date.try(:[], 0, 4)}",
          '</YEAR>'
        ]
      end

      def tr_group
        alternatives = @manifestation.title_alternative.try(:split, '||') || []
        [
          '<TR>',
          "TRD=#{@manifestation.original_title}",
          "TRR=#{@manifestation.title_transcription}",
          "TRVR=#{alternatives[0]}",
          "TRVR=#{alternatives[1]}",
          '</TR>'
        ]
      end

      def vt_group
        results = []
        type_ids = TitleType.where("note = 'for nacsis' and name <> 'UTL'").pluck(:id)
        if type_ids.present?
          @manifestation.work_has_titles.where(title_type_id: type_ids).each do |wht|
            alternatives = wht.manifestation_title.title_alternative.try(:split, '||') || []
            results += [
              '<VT>',
              "VTK=#{wht.title_type.name}",
              "VTD=#{wht.manifestation_title.title}",
              "VTR=#{wht.manifestation_title.title_transcription}",
              "VTVR=#{alternatives[0]}",
              "VTVR=#{alternatives[1]}",
              '</VT>'
            ]
          end
        end
        results
      end

      def pub_group
        [
          '<PUB>',
          "PUBP=#{@manifestation.place_of_publication}",
          "PUBL=#{@manifestation.publishers.first.try(:full_name)}",
          "PUBDT=#{@manifestation.date_of_publication_string}",
          "PUBF=#{}",
          '</PUB>'
        ]
      end

      def phys_group
        phys_array = @manifestation.size.try(:split,'||',-1)
        results = []
        if phys_array.try(:size) == 4
          results += [
            '<PHYS>',
            "PHYSP=#{phys_array[0]}",
            "PHYSI=#{phys_array[1]}",
            "PHYSS=#{phys_array[2]}",
            "PHYSA=#{phys_array[3]}",
            '</PHYS>'
          ]
        end
        results
      end

      def cw_group # book only
        results = []
        child_manifestations = @manifestation.derived_manifestations || []
        child_manifestations.each do |manifestation|
          cwvr_array = manifestation.title_alternative.try(:split,'||') || []
          results += [
            '<CW>',
            "CWT=#{manifestation.original_title}",
            "CWA=#{manifestation.creators.first.try(:full_name)}",
            "CWR=#{manifestation.title_transcription}",
            "CWVR=#{cwvr_array[0]}",
            "CWVR=#{cwvr_array[1]}",
            '</CW>'
          ]
        end
        results
      end

      def ptbl_group # book only
        results = []
        parent_manifestations = @manifestation.original_manifestations || []
        parent_manifestations.each do |manifestation|
          if manifestation.nacsis_identifier
            parent_nacsis_cat = NacsisCat.search(dbs: [:book], id: manifestation.nacsis_identifier)
            parent_nacsis_cat = parent_nacsis_cat[:book].try(:first)
            if parent_nacsis_cat
              results += [
                '<PTBL>',
                "PTBID=#{manifestation.nacsis_identifier}",
                "PTBK=#{manifestation.children.first.manifestation_relationship_type.try(:name)}",
                "PTBNO=#{manifestation.note}",
                '</PTBL>'
              ]
            end
          end
        end
        results
      end

      def al_group
        results = []
        @manifestation.creators.each do |creator|
          if creator.agent_identifier
            results += [
              '<AL>',
              "AID=#{creator.agent_identifier}",
              "AF=#{@manifestation.creates.where(:agent_id => creator.id).first.create_type.try(:name)}",
              "AFLG=#{}",
              '</AL>'
            ]
          else
            alternatives = creator.full_name_alternative.try(:split, '||') || []
            results += [
              '<AL>',
              "AHDNG=#{creator.full_name}",
              "AHDNGR=#{creator.full_name_transcription}",
              "AHDNGVR=#{alternatives[0]}",
              "AHDNGVR=#{alternatives[1]}",
              "AF=#{@manifestation.creates.where(:agent_id => creator.id).first.create_type.try(:name)}",
              "AFLG=#{}",
              '</AL>'
            ]
          end
        end
        results
      end

      def utl_group # book only
        results = []
        title_type = TitleType.find_by_name('UTL')
        utl_titles = @manifestation.manifestation_titles.where('work_has_titles.title_type_id' => title_type.id)
        utl_titles.each do |title|
          if title.nacsis_identifier
            results += [
              '<UTL>',
              "UTID=#{title.nacsis_identifier}",
              "UTINFO=#{title.note}",
              "UTFLG=#{}",
              '</UTL>'
            ]
          else
            alternatives = title.title_alternative.try(:split, '||') || []
            results += [
              '<UTL>',
              "UTHDNG=#{title.title}",
              "UTHDNGR=#{title.title_transcription}",
              "UTHDNGVR=#{alternatives[0]}",
              "UTHDNGVR=#{alternatives[1]}",
              "UTINFO=#{title.note}",
              "UTFLG=#{}",
              '</UTL>'
            ]
          end
        end
        results
      end

      def cls_group # book only
        [
          '<CLS>',
            "CLSK=#{}",
            "CLSD=#{}",
          '</CLS>'
        ]
      end

      def sh_group
        results = []
        @manifestation.subjects.where(:note => 'for nacsis data').each do |subject|
          alternatives = subject.term_alternative.try(:split, '||') || []
          results += [
            '<SH>',
            "SHT=#{'NDLSH'}", # 件名標目表の種類コード表のテーブルが必要
            "SHD=#{subject.term}",
            "SHK=#{subject.subject_type.name}",
            "SHR=#{subject.term_transcription}",
            "SHVR=#{alternatives[0]}",
            "SHVR=#{alternatives[1]}",
            '</SH>'
          ]
        end
        results
      end

      def get_nacsis_language(type_name)
        languages = []
        language_type = LanguageType.where(:name => type_name)
        if language_type
          work_has_languages = @manifestation.work_has_languages.where(:language_type_id => language_type)
          languages = work_has_languages.map {|whl| whl.language.iso_639_2 }
        end
        languages.join
      end

      def gateway_upload_cat_url
        "#{gateway_config['gw_url']}cat/gateway.json"
      end

      def http_post_value(url, query)
        uri = URI.parse(url)

        http = Net::HTTP.new(uri.host, uri.port)
        resp = http.post(uri.path, query.to_query)

        JSON.parse(resp.body)
      end

      def create_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        return nil if nacsis_cat.blank?

        child_manifestation = nil
        child_manifestation = new_root_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        created_manifestations = []
        created_manifestations << child_manifestation

        ptbk = {}

        # 親書誌情報の登録
        nacsis_cat.detail[:ptb_info].each do |ptbl_record|
          parent_manifestation = Manifestation.where(:nacsis_identifier => ptbl_record['PTBID']).first
          if parent_manifestation
            created_manifestations << parent_manifestation
          else
            parent_nacsis_cat = NacsisCat.search(dbs: [:book], id: ptbl_record['PTBID'])
            parent_nacsis_cat = parent_nacsis_cat[:book].try(:first)
            if parent_nacsis_cat
              created_manifestations << new_root_manifestation_from_nacsis_cat(parent_nacsis_cat, book_types)
            else
              unless ptbl_record['PTBTR'].nil?
                created_manifestations <<
                  Manifestation.where(:original_title => ptbl_record['PTBTR']).first_or_create do |m|
                    if m.new_record?
                      m.nacsis_identifier = ptbl_record['PTBID']
                      m.title_transcription = ptbl_record['PTBTRR']
                      m.title_alternative = arraying(ptbl_record['PTBTRVR']).join('||')
                      m.note = ptbl_record['PTBNO']
                    end
                  end
              end
            end
          end
          ptbk[ptbl_record['PTBID']] = ptbl_record['PTBK']
        end
        # 親書誌関係の登録
        created_manifestations.reverse.each do |parent|
          created_manifestations.each do |child|
            break if parent == child
            parent.derived_manifestations << child
          end

          # 構造の種類設定
          parent.derived_manifestations.each do |derived|
            derived.parents.each do |child|
              child.manifestation_relationship_type_id = ManifestationRelationshipType.where(:name => ptbk[parent.nacsis_identifier]).first.try(:id)
              child.save!
            end
          end

        end

        # 内容著作注記の登録
        nacsis_cat.detail[:cw_info].each do |cw_record|
          attrs = {}
          attrs[:original_title] = cw_record['CWT']
          attrs[:title_transcription] = cw_record['CWR']
          attrs[:title_alternative] = arraying(cw_record['CWVR']).join('||')
          unless cw_record['CWA'].nil?
            attrs[:creators] = []
            attrs[:creators] << Agent.where(:full_name => cw_record['CWA'].to_s).first_or_create
          end
          child_manifestation.derived_manifestations << Manifestation.create(attrs)
        end

        child_manifestation
      end

      def new_root_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        case nacsis_cat.detail[:vol_info].size
        when 0 # VOLGが0件の場合
          root_manifestation = new_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        else   # VOLGが1件以上の場合
          root_manifestation = new_manifestation_from_nacsis_cat(nacsis_cat, book_types)

          volg_manifestations = []
          nacsis_cat.detail[:vol_info].each do |volg|
            volg_manifestation = new_manifestation_from_nacsis_cat(nacsis_cat, book_types, volg)
            volg_manifestations << volg_manifestation
          end
          series_statement = new_series_statement_from_nacsis_cat(nacsis_cat)
          series_statement.periodical = false
          series_statement.root_manifestation = root_manifestation
          series_statement.manifestations << root_manifestation
          series_statement.manifestations += volg_manifestations
          series_statement.save!
        end
        root_manifestation
      end

      def new_manifestation_from_nacsis_cat(nacsis_cat, book_types, volg_info = {})
        return nil if nacsis_cat.blank? || book_types.blank?
        nacsis_info = nacsis_cat.detail
        attrs = {}
        if nacsis_info[:source].nil?
          attrs[:catalog_id] = Catalog.where(:name => 'nacsis').first.id
        else
          attrs[:catalog_id] = Catalog.where(:nacsis_identifier => nacsis_info[:source]).first.id
        end
        attrs[:original_title] = nacsis_info[:subject_heading]
        attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
        attrs[:title_alternative] = nacsis_info[:title_alternative]
        attrs[:place_of_publication] = nacsis_info[:publication_place].try(:join, ",")
        attrs[:date_of_publication_string] = nacsis_info[:publication_date].try(:join, ",")
        attrs[:note] = nacsis_info[:note]
        attrs[:marc_number] = nacsis_info[:marc]
        attrs[:pub_date] = nacsis_info[:year1]
        attrs[:dis_date] = nacsis_info[:year2]
        attrs[:lccn] = nacsis_info[:lccn]
        attrs[:issn] = nacsis_info[:issn]
        attrs[:carrier_type_id] = CarrierType.where(:nacsis_identifier => nacsis_info[:gmd]).first.try(:id)
        attrs[:sub_carrier_type_id] = SubCarrierType.where(:nacsis_identifier => nacsis_info[:smd]).first.try(:id)
        attrs[:original] = true if nacsis_info[:repro] == 'c'
        attrs[:edition_display_value] = nacsis_info[:ed]

        if nacsis_info[:size].present?
          size_array = [
            nacsis_info[:size].try(:[],'PHYSP'),
            nacsis_info[:size].try(:[],'PHYSI'),
            nacsis_info[:size].try(:[],'PHYSS'),
            nacsis_info[:size].try(:[],'PHYSA')
          ]
          attrs[:size] = size_array.join('||')
        end

        # 出版国がnilの場合、unknownを設定する。
        if nacsis_info[:pub_country]
          attrs[:country_of_publication] = nacsis_info[:pub_country]
        else
          attrs[:country_of_publication] = Country.where(:name => 'unknown').first
        end

        # テキストの言語により、和書または洋書を設定する。
        if nacsis_info[:text_language].present?
          if nacsis_info[:text_language].first.name == 'Japanese'
            attrs[:manifestation_type] = book_types.detect {|bt| /japanese/io =~ bt.name }
            attrs[:jpn_or_foreign] = 0
          else
            attrs[:manifestation_type] = book_types.detect {|bt| /foreign/io =~ bt.name }
            attrs[:jpn_or_foreign] = 1
          end
        else
          attrs[:manifestation_type] = book_types.detect {|bt| "unknown" == bt.name }
          attrs[:jpn_or_foreign] = nil
        end

        # 関連テーブル：著者の設定
        attrs[:creators] = []
        af = {}
        nacsis_info[:creators].each do |creator|
          #TODO 著者名典拠IDが存在する場合、nacsisの著者名典拠DBからデータを取得する。
          attrs[:creators] <<
            Agent.where(:full_name => creator['AHDNG'].to_s).first_or_create do |p|
              if p.new_record?
                p.agent_identifier = creator['AID']
                p.full_name_transcription = creator['AHDNGR']
                p.full_name_alternative = arraying(creator['AHDNGVR']).join('||')
              end
            end
          af[creator['AHDNG']] = creator['AF']
        end

        # 関連テーブル：出版者の設定
        attrs[:publishers] = []
        nacsis_info[:publishers].each do |pub|
          attrs[:publishers] << Agent.where(:full_name => pub.to_s).first_or_create
        end

        # 関連テーブル：件名の設定
        attrs[:subjects] = []
        nacsis_info[:subjects].each do |subject|
          subject_type = SubjectType.where(:name => subject['SHK']).first
          subject_type = SubjectType.where(:name => 'K').first if subject_type.nil?
          if subject['SHD'].present? && subject_type
            sub = Subject.where(["term = ? and subject_type_id = ?", subject['SHD'].to_s, subject_type.id]).first
            if sub
              attrs[:subjects] << sub
            else
              attrs[:subjects] << Subject.create(:term => subject['SHD'],
                                                 :term_transcription => subject['SHR'],
                                                 :term_alternative => arraying(subject['SHVR']).join('||'),
                                                 :subject_type_id => subject_type.id)
            end
          end
        end

        attrs[:identifiers] = []
        if nacsis_info[:gpon]
          identifier_type = IdentifierType.where(:name => 'gpon').first_or_create
          attrs[:identifiers] <<
           Identifier.create(:body => nacsis_info[:gpon], :identifier_type_id => identifier_type.id)
        end

        if nacsis_cat.book?
          unless nacsis_info[:vol_info].size >= 1 && volg_info.present?
            attrs[:nacsis_identifier] = nacsis_cat.ncid
            attrs[:nbn] = nacsis_info[:nbn]
          end

          attrs[:ndc] = get_latest_ndc(nacsis_info[:cls_info])
          # 関連テーブル：版冊次の設定
          if volg_info.present?
            if volg_info['ISBN']
              identifier_type = IdentifierType.where(:name => 'isbn').first_or_create
              attrs[:identifiers] <<
                Identifier.create(:body => volg_info['ISBN'], :identifier_type_id => identifier_type.id)
            end
            attrs[:edition_display_value] = volg_info['VOL']
            attrs[:price_string] = volg_info['PRICE']
            attrs[:wrong_isbn] = volg_info['XISBN']
          end
          if nacsis_info[:ndlcn].present?
            identifier_type = IdentifierType.where(:name => 'ndlcn').first_or_create
            nacsis_info[:ndlcn].uniq.each do |ndlcn|
              attrs[:identifiers] <<
                Identifier.create(:body => ndlcn, :identifier_type_id => identifier_type.id)
            end
          end
          nacsis_info[:other_number].each do |othn|
            othn_array = othn.split(':')
            name = othn_array[0]
            val = othn_array[1]
            unless name.nil? || val.nil?
              identifier_type = IdentifierType.where(:name => name.downcase).first_or_create
              attrs[:identifiers] <<
                Identifier.create(:body => val, :identifier_type_id => identifier_type.id)
            end
          end
        else # root_manifestation用
          attrs[:nacsis_identifier] = nacsis_cat.ncid
          nacsis_info[:xissn].each do |xissn|
            identifier_type = IdentifierType.where(:name => 'xissn').first_or_create
            attrs[:identifiers] <<
              Identifier.create(:body => xissn, :identifier_type_id => identifier_type.id)
          end
          if nacsis_info[:ndlpn]
            identifier_type = IdentifierType.where(:name => 'ndlpn').first_or_create
            attrs[:identifiers] <<
              Identifier.create(:body => nacsis_info[:ndlpn], :identifier_type_id => identifier_type.id)
          end
          if nacsis_info[:coden]
            identifier_type = IdentifierType.where(:name => 'coden').first_or_create
            attrs[:identifiers] <<
              Identifier.create(:body => nacsis_info[:coden], :identifier_type_id => identifier_type.id)
          end
          if nacsis_info[:ulpn]
            identifier_type = IdentifierType.where(:name => 'ulpn').first_or_create
            attrs[:identifiers] <<
              Identifier.create(:body => nacsis_info[:ulpn], :identifier_type_id => identifier_type.id)
          end
          if nacsis_info[:ndlcln]
            identifier_type = IdentifierType.where(:name => 'ndlcln').first_or_create
            attrs[:identifiers] <<
              Identifier.create(:body => nacsis_info[:ndlcln], :identifier_type_id => identifier_type.id)
          end
          if nacsis_info[:ndlhold]
            identifier_type = IdentifierType.where(:name => 'ndlhold').first_or_create
            attrs[:identifiers] <<
              Identifier.create(:body => nacsis_info[:ndlhold], :identifier_type_id => identifier_type.id)
          end
          if nacsis_info[:freq]
            attrs[:frequency_id] = Frequency.find_by_nii_code(nacsis_info[:freq]).try(:id) || Frequency.find_by_nii_code('u').try(:id)
          end
          attrs[:manifestation_type_id] = ManifestationType.where(:nacsis_identifier => nacsis_info[:type]).first.try(:id)
          attrs[:price_string] = nacsis_info[:price]
        end

        manifestation = Manifestation.create(attrs)
        manifestation.work_has_languages << new_work_has_languages_from_nacsis_cat(nacsis_cat,manifestation)
        manifestation.work_has_titles << new_work_has_titles_from_nacsis_cat(nacsis_cat)

        if nacsis_info[:vlyr]
          vlyr_ary = []
          nacsis_info[:vlyr].each do |vlyr|
            vlyr_ary << ManifestationExtext.new(:name => 'VLYR', :value => vlyr)
          end
          manifestation.manifestation_extexts = vlyr_ary
        end

        # 関連テーブル：著者 役割表示の設定
        manifestation.creates.each do |cre|
          cre.create_type_id = CreateType.where(:name => af[manifestation.creators.where(:id => cre.agent_id).first.full_name]).first.try(:id)
          cre.save!
        end

        manifestation
      end

      def create_series_with_relation_from_nacsis_cat(nacsis_cat, book_types)
        return nil if nacsis_cat.blank? || book_types.blank?

        # 元の雑誌情報作成
        series_statement = create_series_statement_from_nacsis_cat(nacsis_cat, book_types)

        # 遍歴ファミリーの作成
        relationship_family = create_family_from_fid(nacsis_cat.fid)

        if relationship_family
          # 元の雑誌をファミリーに紐づける
          relationship_family.series_statements = []
          relationship_family.series_statements << series_statement

          nacsis_cat.detail[:bhn_info].each do |bhn|
            result_bhn = NacsisCat.search(dbs: [:serial], id: bhn['BHBID'])
            nacsis_cat_bhn = result_bhn[:serial].first

            # 遍歴の雑誌情報作成
            series_statement_bhn = SeriesStatement.where(:nacsis_series_statementid => nacsis_cat_bhn.ncid).first
            if series_statement_bhn.nil?
              series_statement_bhn = create_series_statement_from_nacsis_cat(nacsis_cat_bhn, book_types)
            end

            # 雑誌同士の関連情報作成
            series_statement_relationship = SeriesStatementRelationship.new(:seq => 1, :source => 1)
            if relationship_before?(bhn['BHK'].to_s)
              series_statement_relationship.before_series_statement_relationship = series_statement_bhn
              series_statement_relationship.after_series_statement_relationship = series_statement
            else
              series_statement_relationship.before_series_statement_relationship = series_statement
              series_statement_relationship.after_series_statement_relationship = series_statement_bhn
            end
            series_statement_relationship.series_statement_relationship_type = get_relationship_type(bhn['BHK'].to_s)
            series_statement_relationship.relationship_family = relationship_family
            series_statement_relationship.save!

            # 遍歴ファミリーに遍歴の雑誌情報を関連付ける
            relationship_family.series_statements << series_statement_bhn
          end
        end
        series_statement
      end

      def create_series_statement_from_nacsis_cat(nacsis_cat, book_types)
        return nil if nacsis_cat.blank? || book_types.blank?
        series_statement = SeriesStatement.where(:nacsis_series_statementid => nacsis_cat.ncid).first
        if series_statement.nil?
          series_statement = new_series_statement_from_nacsis_cat(nacsis_cat)
          series_statement.periodical = true
          root_manifestation = new_manifestation_from_nacsis_cat(nacsis_cat, book_types)
          root_manifestation.periodical_master = true
          root_manifestation.save!
          series_statement.root_manifestation = root_manifestation
          series_statement.manifestations << series_statement.root_manifestation
          series_statement.save!
        end
        series_statement
      end

      def new_series_statement_from_nacsis_cat(nacsis_cat)
        return nil if nacsis_cat.blank?
        nacsis_info = nacsis_cat.detail
        attrs = {}
        attrs[:nacsis_series_statementid] = nacsis_cat.ncid
        attrs[:original_title] = nacsis_info[:subject_heading]
        attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
        attrs[:issn] = nacsis_info[:issn]
        attrs[:note] = nacsis_info[:note]
        attrs[:publication_status_id] = PublicationStatus.find_by_name(nacsis_info[:pstat]).try(:id)
        SeriesStatement.new(attrs)
      end

      def new_work_has_languages_from_nacsis_cat(nacsis_cat, manifestation)
        return [] if nacsis_cat.blank?
        nacsis_info = nacsis_cat.detail
        whl_ary = []
        {:title_language => 'title', :text_language => 'body', :original_language => 'original'}.each do |lang, type|
          nacsis_info[lang].each do |language|
            whl = WorkHasLanguage.new
            whl.language = language
            whl.language_type = LanguageType.find_by_name(type)
            whl.work = manifestation
            whl_ary << whl
          end
        end
        whl_ary
      end

      def new_work_has_titles_from_nacsis_cat(nacsis_cat)
        return [] if nacsis_cat.blank?
        nacsis_info = nacsis_cat.detail
        wht_ary = []
        nacsis_info[:other_titles].each do |other_title|
          wht = WorkHasTitle.new
          title = Title.find_by_title(other_title['VTD'])
          if title
            wht.manifestation_title = title
          else
            wht.manifestation_title =
              Title.create(:title => other_title['VTD'],
                           :title_transcription => other_title['VTR'],
                           :title_alternative => arraying(other_title['VTVR']).join('||'))
          end
          wht.title_type = TitleType.find_by_name(other_title['VTK'])
          wht_ary << wht
        end
        if nacsis_cat.book?
          nacsis_info[:utl_info].each do |utl_info|
            wht = WorkHasTitle.new
            title = Title.find_by_nacsis_identifier(utl_info['UTID'])
            if title
              wht.manifestation_title = title
            else
              wht.manifestation_title =
                Title.create(:title => utl_info['UTHDNG'],
                             :title_transcription => utl_info['UTHDNGR'],
                             :title_alternative => arraying(utl_info['UTHDNGVR']).join('||'),
                             :note => utl_info['UTINFO'],
                             :nacsis_identifier => utl_info['UTID'])
            end
            wht.title_type = TitleType.find_by_name('UTL')
            wht_ary << wht
          end
        end
        wht_ary
      end

      def create_family_from_fid(fid)
        return nil if fid.nil?
        RelationshipFamily.where(:fid => fid).first_or_create do |rf|
          rf.display_name = "CHANGE_#{fid}" if rf.new_record?
        end
      end

      def get_latest_ndc(cls_hash)
        return nil if cls_hash.blank?
        return_val = nil
        ['NDC9','NDC8','NDC7','NDC6','NDC'].each do |ndc|
          if cls_hash[ndc]
            return_val = cls_hash[ndc]
            break
          end
        end
        return_val
      end

      def get_relationship_type(type_str)
        return nil if type_str.nil?
        case type_str[0, 1]
        when 'C' # 継続
          SeriesStatementRelationshipType.where(:typeid => '1').first
        when 'A' # 吸収
          SeriesStatementRelationshipType.where(:typeid => '2').first
        when 'S' # 派生
          SeriesStatementRelationshipType.where(:typeid => '3').first
        else     # 未登録
          SeriesStatementRelationshipType.where(:typeid => '30').first
        end
      end

      def relationship_before?(type_str)
        return nil if type_str.nil?
        if type_str[1, 1] == 'F' # 前誌
          true
        else # 後誌
          false
        end
      end

      def arraying(obj)
        case true
        when obj.blank?
          []
        when obj.is_a?(Array)
          obj
        else
          [obj]
        end
      end
  end

  def initialize(*args)
    options = args.extract_options!
    options.assert_valid_keys(:record)

    @record = options[:record]
  end

  def book?
    !serial?
  end

  def serial?
    @record['_DBNAME_'] == 'SERIAL'
  end

  def item?
    @record['_DBNAME_'] == 'BHOLD' || @record['_DBNAME_'] == 'SHOLD'
  end

  def ncid
    @record['ID']
  end

  def isbn
    if book?
      map_attrs(@record['VOLG'], 'ISBN').compact
    else
      nil
    end
  end

  def issn
    @record['ISSN']
  end

  def fid
    if serial?
      @record['FID']
    else
      nil
    end
  end

  def nbn
    if book?
      arraying(@record['NBN']).compact
    else
      nil
    end
  end

  def class_id_pair
    return nil if serial?
    hash = {}
    arraying(@record['CLS']).each do |cl|
      hash.store(cl['CLSK'], cl['CLSD'])
    end
    hash
  end

  def manifestation
    Manifestation.find_by_nacsis_identifier(@record['ID'])
  end

  def summary
    return nil unless @record

    if item?
      hash = {
        :database => @record['_DBNAME_'],
        :hold_id => @record['ID'],
        :library_abbrev => @record['LIBABL'],
        :cln => map_attrs(@record['HOLD'], 'CLN').join(' '),
        :rgtn => map_attrs(@record['HOLD'], 'RGTN').join(' '),
      }

    else
      hash = {
        :subject_heading => @record['TR'].try(:[], 'TRD'),
        :publisher => map_attrs(@record['PUB']) {|x| [x['PUBL'], x['PUBDT']] },
      }

      if serial?
        hash[:display_number] = [@record['VLYR']].flatten
      else
        hash[:series_title] =
          map_attrs(@record['PTBL']) {|x| [x['PTBTR'], x['PTBNO']] }
      end
    end

    hash
  end

  def detail
    return nil unless @record

    {
      :subject_heading => @record['TR'].try(:[], 'TRD'),
      :subject_heading_reading => @record['TR'].try(:[], 'TRR'),
      :title_alternative => map_attrs(@record['TR'], 'TRVR').join('||'),
      :other_titles => arraying(@record['VT']),
      :publisher => map_attrs(@record['PUB']) {|pub| join_attrs(pub, ['PUBP', 'PUBL', 'PUBDT', 'PUBF'], ',') },
#      :publish_year => join_attrs(@record['YEAR'], ['YEAR1', 'YEAR2'], '-'),
      :year1 => @record['YEAR'].try(:[], 'YEAR1'),
      :year2 => @record['YEAR'].try(:[], 'YEAR2'),
      :physical_description => join_attrs(@record['PHYS'], ['PHYSP', 'PHYSI', 'PHYSS', 'PHYSA'], ';'),
      :pub_country => @record['CNTRY'].try {|cntry| Country.where(:marc21 => cntry).first },
      :title_language => get_languages(@record['TTLL']),
      :text_language => get_languages(@record['TXTL']),
      :original_language => get_languages(@record['ORGL']),
      :author_heading => map_attrs(@record['AL']) do |al|
        if al['AHDNG'].blank? && al['AHDNGR'].blank?
          nil
        elsif al['AHDNG'] && al['AHDNGR']
          "#{al['AHDNG']}(#{al['AHDNGR']})"
        else
          al['AHDNG'] || al['AHDNGR']
        end
      end.compact,
      :subject => map_attrs(@record['SH'], 'SHD').compact.uniq,
      :note => arraying(@record['NOTE']).compact.join(" "),
      :publication_place => map_attrs(@record['PUB'], 'PUBP').compact.uniq,
      :publication_date => map_attrs(@record['PUB'], 'PUBDT').compact.uniq,
      :size => @record['PHYS'],
      :creators => arraying(@record['AL']),
      :publishers => map_attrs(@record['PUB'], 'PUBL').compact.uniq,
      :subjects => arraying(@record['SH']),
      :marc => @record['MARCID'],
      :lccn => @record['LCCN'],
      :gpon => @record['GPON'],
      :source => @record['SOURCE'],
      :gmd => @record['GMD'],
      :smd => @record['SMD'],
      :repro => @record['REPRO'],
      :ed => @record['ED'],
      :issn => issn
    }.tap do |hash|
      if book?
        hash[:vol_info] = arraying(@record['VOLG'])
        hash[:cw_info] = arraying(@record['CW'])
        hash[:nbn] = nbn.join(",")
        hash[:ndlcn] = arraying(@record['NDLCN'])
        hash[:other_number] = arraying(@record['OTHN'])
        hash[:ptb_info] = arraying(@record['PTBL'])
        hash[:utl_info] = arraying(@record['UTL'])
        hash[:cls_info] = class_id_pair
      else
        hash[:xissn] = arraying(@record['XISSN'])
        hash[:price] = @record['PRICE']
        hash[:fid] = fid
        hash[:pstat] = @record['PSTAT']
        hash[:freq] = @record['FREQ']
        hash[:type] = @record['TYPE']
        hash[:bhn_info] = arraying(@record['BHNT'])
        hash[:ndlpn] = @record['NDLPN']
        hash[:coden] = @record['CODEN']
        hash[:ulpn] = @record['ULPN']
        hash[:ndlcln] = @record['NDLCLN']
        hash[:ndlhold] = @record['NDLHOLD']
        hash[:vlyr] = arraying(@record['VLYR'])
      end
      hash[:ncid] = ncid
    end
  end

  def request_summary
    return nil unless @record

    {
      :subject_heading => @record['TR'].try(:[], 'TRD'),
      :publisher => map_attrs(@record['PUB']) {|pub| join_attrs(pub, ['PUBP', 'PUBL', 'PUBDT'], ',') }.join(' '),
      :pub_date => join_attrs(@record['YEAR'], ['YEAR1', 'YEAR2'], '-'),
      :physical_description => join_attrs(@record['PHYS'], ['PHYSP', 'PHYSI', 'PHYSS', 'PHYSA'], ';'),
      :series_title => if book?
          map_attrs(@record['PTBL']) {|x| [x['PTBTR'], x['PTBNO']].compact.join(' ') }.join(',')
        else
          nil
        end,
      :isbn => isbn.try(:join, ','),
      :pub_country => @record['CNTRY'], # :pub_country => @record['CNTRY'].try {|cntry| Country.where(:alpha_2 => cntry.upcase).first }, # XXX: 国コード体系がCountryとは異なる: http://www.loc.gov/marc/countries/countries_code.html
      :title_language => @record['TTLL'].try {|lang| Language.where(:iso_639_2 => lang).first },
      :text_language => @record['TXTL'].try {|lang| Language.where(:iso_639_2 => lang).first },
      :classmark => if book?
          map_attrs(@record['CLS']) {|cl| join_attrs(cl, ['CLSK', 'CLSD'], ':') }.join(';')
        else
          nil
        end,
      :author_heading => map_attrs(@record['AL']) do |al|
        if al['AHDNG'].blank? && al['AHDNGR'].blank?
          nil
        elsif al['AHDNG'] && al['AHDNGR']
          "#{al['AHDNG']}(#{al['AHDNGR']})"
        else
          al['AHDNG'] || al['AHDNGR']
        end
      end.compact.join(','),
      :subject => map_attrs(@record['SH'], 'SHD').join(','),
      :ncid => ncid,
    }.tap do |hash|
    end
  end

  def persisted?
    false
  end

  private

    def map_attrs(str_or_ary, key = nil, &block)
      return [] unless str_or_ary
      ary = [str_or_ary].flatten
      if block
        ary.map(&block)
      else
        ary.map {|x| x[key] }
      end
    end

    def join_attrs(obj, keys, str)
      if obj
        ary = keys.map {|k| obj[k] }.compact
        ary.blank? ? nil : ary.join(str)
      else
        obj
      end
    end

    def arraying(obj)
      case true
      when obj.blank?
        []
      when obj.is_a?(Array)
        obj
      else
        [obj]
      end
    end

    def get_languages(lang_str)
      languages = []
      if lang_str.is_a?(String)
        lang_str.each_char.each_slice(3).map{|a| a.join}.each do |lang|
          #if lang == 'und'
          #  languages << Language.where(:iso_639_2 => 'unknown').first
          #else
            languages << Language.where(:iso_639_2 => lang).first
          #end
        end
      end
      languages.compact
    end
end

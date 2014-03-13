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
        :id, :isbn, :issn,
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

      def create_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        return nil if nacsis_cat.blank?
        created_manifestations = []

        #子書誌情報の登録
        child_manifestation = new_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        child_manifestation.save!
        child_manifestation.work_has_languages = new_work_has_languages_from_nacsis_cat(nacsis_cat)
        created_manifestations << child_manifestation

        #親書誌情報の登録
        nacsis_cat.detail[:ptb_info].each do |ptbl_record|
          parent_manifestation = Manifestation.where(:nacsis_identifier => ptbl_record['PTBID']).first
          if parent_manifestation
            created_manifestations << parent_manifestation
          else
            parent_result = NacsisCat.search(dbs: [:book], id: ptbl_record['PTBID'])
            if parent_result[:book].blank?
              unless ptbl_record['PTBTR'].nil?
                created_manifestations <<
                  Manifestation.where(:original_title => ptbl_record['PTBTR']).first_or_create do |m|
                    if m.new_record?
                      m.nacsis_identifier = ptbl_record['PTBID']
                      m.title_transcription = ptbl_record['PTBTRR']
                      m.title_alternative_transcription = ptbl_record['PTBTRVR']
                      m.note = ptbl_record['PTBNO']
                    end
                  end
              end
            else
              parent_manifestation = new_manifestation_from_nacsis_cat(parent_result[:book].first, book_types)
              parent_manifestation.save!
              parent_manifestation.work_has_languages = new_work_has_languages_from_nacsis_cat(parent_result[:book].first)
              created_manifestations << parent_manifestation
            end
          end
        end
        #親書誌関係の登録
        created_manifestations.reverse.each do |parent|
          created_manifestations.each do |child|
            break if parent == child
            parent.derived_manifestations << child
          end
        end
        child_manifestation
      end

      def new_manifestation_from_nacsis_cat(nacsis_cat, book_types)
        return nil if nacsis_cat.blank? || book_types.blank?
        nacsis_info = nacsis_cat.detail
        attrs = {}
        attrs[:nacsis_identifier] = nacsis_cat.ncid
        attrs[:external_catalog] = 2
        attrs[:original_title] = nacsis_info[:subject_heading]
        attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
        attrs[:title_alternative] = nacsis_info[:title_alternative].try(:join,",")
        attrs[:title_alternative_transcription] = nacsis_info[:title_alternative_transcription].try(:join, ",")
        attrs[:place_of_publication] = nacsis_info[:publication_place].try(:join, ",")
        attrs[:note] = nacsis_info[:note]
        attrs[:marc_number] = nacsis_info[:marc]
        attrs[:date_of_publication_string] = nacsis_info[:publish_year]
        attrs[:size] = nacsis_info[:size]
        attrs[:lccn] = nacsis_info[:lccn]

        # 出版国がnilの場合、unknownを設定する。
        if nacsis_info[:pub_country]
          attrs[:country_of_publication] = nacsis_info[:pub_country]
        else
          attrs[:country_of_publication] = Country.where(:name => 'unknown').first
        end

        # タイトルの言語により、和書または洋書を設定する。
        if nacsis_info[:title_language].present?
          if nacsis_info[:title_language].first.name == 'Japanese'
            attrs[:manifestation_type] = book_types.detect {|bt| /japanese/io =~ bt.name }
          else
            attrs[:manifestation_type] = book_types.detect {|bt| /foreign/io =~ bt.name }
          end
        else
          attrs[:manifestation_type] = book_types.detect {|bt| "unknown" == bt.name }
        end

        # 関連テーブル：著者の設定
        attrs[:creators] = []
        nacsis_info[:creators].each do |creator|
          #TODO 著者名典拠IDが存在する場合、nacsisの著者名典拠DBからデータを取得する。
          attrs[:creators] <<
            Agent.where(:full_name => creator['AHDNG'].to_s).first_or_create do |p|
              if p.new_record?
                p.agent_identifier = creator['AID']
                p.full_name_transcription = creator['AHDNGR']
                p.full_name_alternative_transcription = creator['AHDNGVR']
              end
            end
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
                                                 :subject_type_id => subject_type.id)
            end
          end
        end

        if nacsis_cat.book?
          attrs[:nbn] = nacsis_info[:nbn]
          attrs[:ndc] = get_latest_ndc(nacsis_info[:cls_info])
          # 関連テーブル：ISBNの設定
          identifier_type = IdentifierType.where(:name => 'isbn').first
          if identifier_type
            attrs[:identifiers] = []
            nacsis_info[:vol_info].each do |vol_info|
              if vol_info['ISBN']
                attrs[:identifiers] << Identifier.create(:body => vol_info['ISBN'],
                                                         :identifier_type_id => identifier_type.id)
              end
            end
          end
        else # root_manifestation用
          attrs[:price_string] = nacsis_info[:price]
        end

        Manifestation.new(attrs)
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
          root_manifestation = new_manifestation_from_nacsis_cat(nacsis_cat, book_types)
          root_manifestation.periodical_master = true
          root_manifestation.save!
          root_manifestation.work_has_languages = new_work_has_languages_from_nacsis_cat(nacsis_cat)
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
        attrs[:periodical] = true
        attrs[:original_title] = nacsis_info[:subject_heading]
        attrs[:title_transcription] = nacsis_info[:subject_heading_reading]
        attrs[:title_alternative] = nacsis_info[:title_alternative].try(:join,",")
        attrs[:issn] = nacsis_info[:issn]
        attrs[:note] = nacsis_info[:note]
        SeriesStatement.new(attrs)
      end

      def new_work_has_languages_from_nacsis_cat(nacsis_cat)
        return [] if nacsis_cat.blank?
        nacsis_info = nacsis_cat.detail
        whl_ary = []
        {:title_language => 'title', :text_language => 'body', :original_language => 'original'}.each do |lang, type|
          nacsis_info[lang].each do |language|
            whl = WorkHasLanguage.new
            whl.language = language
            whl.language_type = LanguageType.find_by_name(type)
            whl_ary << whl
          end
        end
        whl_ary
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
    if serial?
      @record['ISSN']
    else
      nil
    end
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
      :title_alternative => map_attrs(@record['VT'], 'VTD').compact.uniq,
      :title_alternative_transcription => map_attrs(@record['VT'], 'VTR').compact.uniq,
      :publisher => map_attrs(@record['PUB']) {|pub| join_attrs(pub, ['PUBP', 'PUBL', 'PUBDT', 'PUBF'], ',') },
      :publish_year => join_attrs(@record['YEAR'], ['YEAR1', 'YEAR2'], '-'),
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
      :size => @record['PHYS'].try(:[],'PHYSS'),
      :creators => arraying(@record['AL']),
      :publishers => map_attrs(@record['PUB'], 'PUBL').compact.uniq,
      :subjects => arraying(@record['SH']),
      :marc => @record['MARCID'],
      :lccn => @record['LCCN'],
    }.tap do |hash|
      if book?
        hash[:nbn] = nbn.join(",")
        hash[:cls_info] = class_id_pair
        hash[:vol_info] = arraying(@record['VOLG'])
        hash[:ptb_info] = arraying(@record['PTBL'])
        hash[:utl_info] = arraying(@record['UTL'])
      else
        hash[:issn] = issn
        hash[:price] = @record['PRICE']
        hash[:fid] = fid
        hash[:bhn_info] = arraying(@record['BHNT'])
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
          if lang == 'und'
            languages << Language.where(:iso_639_2 => 'unknown').first
          else
            languages << Language.where(:iso_639_2 => lang).first
          end
        end
      end
      languages.compact
    end
end

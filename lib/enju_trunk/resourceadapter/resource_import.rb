# -*- encoding: utf-8 -*-
require 'roo'
require File.join(File.expand_path(File.dirname(__FILE__)), 'import_book')
require File.join(File.expand_path(File.dirname(__FILE__)), 'import_article')
class ResourceImport < EnjuTrunk::ResourceAdapter::Base
  include EnjuTrunk::ImportBook
  include EnjuTrunk::ImportArticle

  class Sheet
    def self.new_from_rows(rows)
      new do |obj|
        obj.rows = rows
      end
    end

    def self.new_from_excelx(excelx, name)
      new do |obj|
        obj.excelx = excelx
        obj.excelx_sheet = name
      end
    end

    def initialize(&block)
      @field = nil
      @rows = nil
      @excelx = nil
      @excelx_sheet = nil
      @manifestation_type = nil

      block.call(self) if block

      if @rows.nil? && @excelx.nil?
        raise ArgumentError, 'no data given'
      elsif @rows && @excelx
        raise ArgumentError, 'rows or excelx should be given'
      elsif @excelx && @excelx_sheet.blank?
        raise ArgumentError, 'no excel sheet name'
      end

      @column_spec = Manifestation.select_output_column_spec(:all)
    end
    attr_accessor :rows, :excelx, :excelx_sheet, :manifestation_type
    attr_writer :field

    def article_sheet?
      SystemConfiguration.get('manifestations.split_by_type') && @manifestation_type.is_article?
    end

    def field
      return @field if @field

      if @excelx
        field_row_num = article_sheet? ? ResourceImport::ARTICLE_HEADER_ROW : ResourceImport::BOOK_HEADER_ROW
        field_row = @excelx.row(field_row_num, @excelx_sheet)
      else
        field_row = @rows.first
      end

      @field = {}
      field_row.each_with_index do |name, i|
        next if name.blank?
        if @field.include?(name)
          raise I18n.t('resource_import_textfile.error.overlap', name: name)
        end
        @field[name] = i.to_i
      end

      @field
    end

    # シートの各行に対するイテレータ。
    # 最初の行(通常ヘッダ行)を1行目とする。
    #
    #   each_row_with_index do |row, i| # iは2, 3, ...
    #     ...
    #   end
    def each_row_with_index
      if @excelx
        data_row_num = article_sheet? ? ResourceImport::ARTICLE_DATA_ROW : ResourceImport::BOOK_DATA_ROW
        data_row_num.upto(@excelx.last_row(@excelx_sheet)) do |row_num|
          yield(@excelx.row(row_num, @excelx_sheet), row_num)
        end
      else
        @rows.each_with_index do |row, i|
          next if i == 0 # 最初の行はヘッダ行
          yield(row, i + 1)
        end
      end
    end

    def each_row
      each_row_with_index do |row, i|
        yield(row)
      end
    end

    def row_num
      if @excelx
        @excelx.last_row(@excelx_sheet)
      else
        @rows.size + 1
      end
    end

    # 内部キーに対応するシート上の項目名を返す。
    # ただし定義されていない内部キーが指定されたら例外を起こす。
    #
    #   field_name('book.isbn') #=> "ISBN"
    #   field_name('book.language') #=> "言語"
    #   field_name('root.language') #=> "シリーズ言語"
    #   field_name('series.issn') #=> "ISSN"
    #   field_name('not.defined') #=> ArgumentError
    def self.field_name(field_key)
      unless Manifestation.output_column_defined?(field_key)
        raise ArgumentError, "unknwon field key: #{field_key.inspect}"
      end

      name = I18n.t("resource_import_textfile.excel.#{field_key}")
      if /\Aroot\./ =~ field_key
        I18n.t("resource_import_textfile.root_prefix") + name
      else
        name
      end
    end

    def self.suffixed_field_name(field_key, suffix)
      "#{field_name(field_key)}#{suffix.to_s}"
    end

    # 内部キーに対応するシート上の項目名を返す。
    def field_name(field_key)
      self.class.field_name(field_key)
    end

    def suffixed_field_name(field_key, suffix)
      self.class.suffixed_field_name(field_key, suffix)
    end

    # 内部キーに対応する配列のインデックスを返す。
    # (インデックスは0から始まる。)
    #
    # シート(書籍)の一行目が以下のとき:
    #
    #   ISBN,タイトル
    #
    # 次のような動作となる:
    #
    #   field_index('book.isbn') #=> 0
    #   field_index('book.original_title') #=> 1
    #   field_index('book.price') #=> nil
    def field_index(field_key)
      field[field_name(field_key)]
    end

    # 分割タイプの項目のインデックスを返す。
    #
    # 指定された内部キーに対応する項目が欠けていた場合
    # (たとえばbook.languageを指定されたところ
    # 言語1、言語3があり言語2がない場合)、
    # ハッシュ中のインデックス値としてnilを設定する。
    # また、対応する項目がまったくなかった場合
    # (たとえばbook.languageが指定されたところ
    # シートに言語Nが一つもなかった場合)にはnilを返す。
    #
    #   field_keys: ひとまとまりとなる項目群の内部キーリスト
    #
    # シート(書籍)の一行目が以下のとき:
    #
    #   ISBN,言語1,言語2,タイトル,言語タイプ2,言語タイプ1
    #
    # 例:
    #
    #   field_index_set(%w(book.language book.language_type))
    #   #=> [{"book.language" => 1, "book.language_type" => 5}, {"book.language" => 2, "book.language_type" => 4}]
    #   field_index_set(%w(book.language book.creator))
    #   #=> [{"book.language" => 1, "book.creator" => nil}, {"book.language" => 2, "book.creator" => nil}]
    #   field_index_set(%w(book.creator)) #=> nil
    #
    # 分割対応でない項目(たとえばISBN)を指定した場合、単に無視される。
    #
    #   field_index_set(%w(book.isbn book.language))
    #   #=> [{"book.language" => 1}, {"book.language" => 2}]
    #   field_index_set(%w(book.isbn))
    #   #=> nil
    def field_index_set(field_keys)
      names = {}
      field_keys.each do |fk|
        next unless @column_spec[fk] == :plural
        name = field_name(fk)
        next unless name
        names[fk] = name
      end
      return nil if names.blank? # 対応する項目がシートになかった

      max_sfx = 0
      index = {}
      names.each do |fk, name|
        regexp = /\A#{Regexp.quote(name)}(\d+)\z/ # suffixed_field_nameに合わせる
        field.each do |k, idx|
          next unless regexp =~ k
          sfx = $1.to_i
          max_sfx = sfx if max_sfx < sfx
          index[fk] ||= {}
          index[fk][sfx] = idx
        end
      end

      set = []
      1.upto(max_sfx) do |sfx|
        set << names.keys.inject(SuffixValue.new(sfx)) do |h, fk|
          h[fk] = index[fk][sfx] if index[fk]
          h
        end
      end

      set
    end

    # 内部キーに対応する項目値を与えられた配列から取り出す。
    # なお、指定された内部キーがシート上にないときはnilを返す。
    #
    # シート(書籍)の一行目が以下のとき:
    #
    #   ISBN,タイトル
    #
    # 次のような動作となる:
    #
    #   row = %w(foo bar baz)
    #   field_data(row, 'book.isbn') #=> "foo"
    #   field_data(row, 'book.original_title') #=> "bar"
    #   field_data(row, 'book.price') #=> nil
    def field_data(row, field_key)
      idx = field_index(field_key)
      return nil unless idx
      row[idx]
    end

    # 分割タイプの項目の値を
    # 与えられた配列から取り出す。
    #
    #   field_keys: ひとまとまりとなる項目群の内部キーリスト
    #
    # シート(書籍)の一行目が以下のとき:
    #
    #   ISBN,言語1,言語2,タイトル,言語タイプ2,言語タイプ1
    #
    # 例:
    #
    #   row = %w(aaa bbb ccc ddd eee fff)
    #   field_data_set(row, %w(book.language book.language_type))
    #   #=> [{"book.language" => "bbb", "book.language_type" => "fff"}, {"book.language" => "ccc", "book.language_type" => "eee"}]
    #   field_data_set(row, %w(book.isbn))
    #   #=> []
    def field_data_set(row, field_keys)
      set = field_index_set(field_keys)
      return nil unless set

      set.each do |s|
        s.each_key do |fk|
          idx = s[fk]
          s[fk] = row[idx]
        end
      end

      set
    end

    def field_name_and_data(row, field_key)
      [field_name(field_key), field_data(row, field_key)]
    end

    def include_all?(field_keys)
      field_keys.all? do |field_key|
        field_index(field_key).present?
      end
    end

    def include_any?(field_keys)
      field_keys.any? do |field_key|
        field_index(field_key).present?
      end
    end

    def filled_all?(row, field_keys)
      field_keys.all? do |field_key|
        field_data(row, field_key).present?
      end
    end

    def filled_any?(row, field_keys)
      field_keys.any? do |field_key|
        field_data(row, field_key).present?
      end
    end

    class SuffixValue
      extend Forwardable
      def initialize(suffix)
        @suffix = suffix
        @hash = {}
      end
      attr_reader :suffix
      def_delegators :@hash, :include?, :[], :[]=, :each, :each_key, :each_value, :all?, :any?
    end
  end # class Sheet

  def initialize
    super
    @field = nil
    @summary = {
      manifestation_imported: 0,
      item_imported: 0,
      manifestation_found: 0,
      item_found: 0,
      failed: 0,
    }
  end

  def import(resource_import_textfile)
    I18n.locale = :ja

    adapter = EnjuTrunk::ResourceAdapter::Base.find_by_classname(resource_import_textfile.adapter_name)
    adapter.logger = logger
    logger.info "adapter=#{adapter.to_s}"
    logger.info "start import: #{Time.now}"

    bm = Benchmark.measure do
        extraparams = eval(resource_import_textfile.extraparams) # FIXME!!!
        filename = resource_import_textfile.resource_import_text.path

        case resource_import_textfile.adapter_name
        when 'Tsvfile_Adapter'
          begin
            logger.info "start read"
            adapter = Tsvfile_Adapter.new
            adapter.check_format(filename)
            rows = []
            adapter.open_import_file(filename) do |csv|
              csv.each {|row| rows << row }
            end
            if rows.blank? || rows.all? {|row| row.blank? }
              raise I18n.t('resource_import_textfile.error.blank_sheet')
            end
            sheet = Sheet.new_from_rows(rows)
            import_sheet(sheet, sheet_extraparams(extraparams, 0), resource_import_textfile)
          rescue => e
            logger.info e.message
            logger.debug "\t" + e.backtrace.join("\n\t")
            with_import_message(resource_import_textfile, true) do |res|
              res.error_msg = e.message
              res.extraparams = "{'wrong_format' => true, 'row_num' => #{sheet.try(:row_num) || 0}, 'filename' => '#{filename}'}"
            end
          end

        when 'Excelfile_Adapter'
          oo = Excelx.new(filename)
          extraparams["sheet"].each_with_index do |sheet_name, i|
            begin
              if !oo.sheets.include?(sheet_name) || oo.first_row(sheet_name).blank?
                raise I18n.t('resource_import_textfile.error.blank_sheet')
              end

              oo.default_sheet = sheet_name
              logger.info "start read sheet: #{sheet_name}"

              sheet = Sheet.new_from_excelx(oo, sheet_name)
              import_sheet(sheet, sheet_extraparams(extraparams, i), resource_import_textfile)
            rescue => e
              logger.info e.message
              logger.debug "\t" + e.backtrace.join("\n\t")
              with_import_message(resource_import_textfile, true) do |res|
                res.error_msg   =  I18n.t('resource_import_textfile.error.failed_to_read_sheet', :sheet => sheet_name)
                res.error_msg  += "<br />#{e.message}"
                res.extraparams = "{'sheet'=>'#{sheet_name}', 'wrong_sheet' => true, 'row_num' => #{sheet.try(:row_num) || 0}, 'filename' => '#{filename}'}"
              end
              next
            end
          end
        end
    end
    logger.info "end import: #{Time.now}"

    logger.info "\n" + Benchmark::CAPTION + bm.to_s
  end

  def self.set_numbering(numbering_name, manifestation_type)
    numbering = Numbering.where(:name => numbering_name).first rescue nil
    unless numbering
      if manifestation_type and manifestation_type.is_article?
        numbering = Numbering.where(:name => 'article').first
      else
        numbering = Numbering.where(:name => 'book').first
      end
    end
    numbering
  end

  private

  def update_summary(type)
    @summary[type] += 1
    @summary
  end

  def sheet_extraparams(extraparams, index)
    extraparams.inject({}) do |hash, (key, obj)|
      if obj.respond_to?(:[])
        hash[key] = obj[index]
      else
        hash[key] ||= obj
      end
      hash
    end
  end

  # DBにmanifestation_typeが入っている必要があるとき
  def get_manifestation_type_from_data(manifestation_type_id)
    return nil unless SystemConfiguration.get('manifestations.split_by_type')
    manifestation_type = ManifestationType.find(manifestation_type_id) rescue nil
    if manifestation_type.nil?
      raise I18n.t('resource_import_textfile.error.manifestation_type_is_nil')
    end
    return manifestation_type
  end

  def check_sheet_can_import(sheet)
    if sheet.article_sheet?
      check_article_header_has_necessary_field(sheet)
    else
      check_book_header_has_manifestation_type(sheet)
      check_book_header_has_necessary_field(sheet)
      check_duplicate_item_identifier(sheet)
    end
  end

  def fix_data(cell)
    return nil unless cell
    cell = cell.to_s.strip

    if cell.match(/^[0-9]+\.0$/)
      return cell.to_i
    elsif cell == 'delete'
      return ''
    elsif cell.blank? or cell.nil?
      return nil
    else
      return cell.to_s
    end
  end

  def fix_boolean(cell, options = { mode: 'create' })
    unless cell
      if options[:mode] == 'delete' or options[:mode] == 'edit' or options[:mode] == 'edit'
        return nil
      else
        return false
      end
    end
    cell = cell.to_s.strip

    if cell.nil? or cell.blank? or cell.upcase == 'FALSE' or cell == ''
      return false
    end
    return true
  end

  def import_sheet(sheet, extraparams, resource_import_textfile)
    logger.debug "  extraparams: #{extraparams.inspect}"

    manifestation_type = get_manifestation_type_from_data(extraparams["manifestation_type"])
    auto_numbering     = extraparams["auto_numbering"]
    numbering          = ResourceImport.set_numbering(extraparams["numbering"], manifestation_type) # XXX: auto_numbering=trueのとき、extraparams["numbering"]に値がないとnumberingがnilとなり自動採番に失敗するが、そのチェックをしなくてもOK?
    not_set_serial_number = extraparams["not_set_serial_number"]
    external_resource  = extraparams["external_resource"]

    sheet.manifestation_type = manifestation_type

    # check sheet
    check_sheet_can_import(sheet)

    # message: import start
    create_import_start_message(sheet, resource_import_textfile)

    # start import data row.
    sheet.each_row_with_index do |row, row_num|
      origin_datas = {}
      row.each_with_index {|value, i| origin_datas[i] = fix_data(value.to_s.strip) }
      import_row_data(origin_datas, row_num, resource_import_textfile, sheet, numbering, auto_numbering, not_set_serial_number, external_resource)

      if row_num % 50 == 0
        Sunspot.commit
        GC.start
      end
    end
    Sunspot.commit
    Rails.cache.write("manifestation_search_total", Manifestation.search.total)

    # message: import end
    create_import_end_message(sheet, resource_import_textfile)
  end

  def import_row_data(origin_datas, row_num, textfile, sheet, numbering, auto_numbering, not_set_serial_number, external_resource)
    logger.info "import start row_num=#{row_num}"

    sheet_name = sheet.excelx_sheet
    with_import_message(textfile) do |res|
      res.body = origin_datas.values.join("\t")
      res.extraparams = "{'sheet'=>'#{sheet_name}'}" if sheet_name

      begin
        ActiveRecord::Base.transaction do
          #TODO do refactring -- start --
          if sheet.article_sheet?
            process_article_data(res, origin_datas, sheet, textfile, numbering)
          else
            process_book_data(res, origin_datas, sheet, textfile, numbering, auto_numbering, not_set_serial_number, external_resource)
          end
          #TODO do refactring -- end --
        end
      rescue => e
        res.failed     = true
        res.error_msg  = sheet_name ? "FAIL[sheet:#{sheet_name} row:#{row_num}]: " : "FAIL[row:#{row_num}]: "
        res.error_msg += e.message
        Rails.logger.info(res.error_msg)
        logger.info res.error_msg
        logger.debug "\t" + e.backtrace.join("\n\t")
        update_summary(:failed)
      end
    end
  end

  def with_import_message(resource_import_textfile, failed = false)
    import_textresult = ResourceImportTextresult.new(
      resource_import_textfile_id: resource_import_textfile.id, failed: failed)
    begin
      yield(import_textresult)
    ensure
      import_textresult.save!
    end
  end

  def create_import_start_message(sheet, resource_import_textfile)
    sheet_name = sheet.excelx_sheet
    with_import_message(resource_import_textfile, true) do |res|
      res.extraparams = "{'sheet'=>'#{sheet_name}'}" if sheet_name
      res.body        = sheet.field.keys.join("\t")
      res.error_msg   = I18n.t('resource_import_textfile.message.read_start')
      res.error_msg  += I18n.t('resource_import_textfile.message.sheet_info', sheet: sheet_name) if sheet_name
      res.error_msg  += sheet.article_sheet? ? article_header_has_out_of_manage(sheet) : book_header_has_out_of_manage(sheet)
    end
  end

  def create_import_end_message(sheet, resource_import_textfile)
    sheet_name = sheet.excelx_sheet
    msg  = I18n.t('resource_import_textfile.message.read_end')
    msg += I18n.t('resource_import_textfile.message.sheet_info', sheet: sheet_name) if sheet_name
    msg += "
      <br />
      #{I18n.t('resource_import_textfile.message.manifestation_imported')}: #{@summary[:manifestation_imported]}
      #{I18n.t('resource_import_textfile.message.item_imported')}: #{@summary[:item_imported]}
      #{I18n.t('resource_import_textfile.message.manifestation_found')}: #{@summary[:manifestation_found]}
      #{I18n.t('resource_import_textfile.message.item_found')}: #{@summary[:item_found]}
      #{I18n.t('resource_import_textfile.message.failed')}: #{@summary[:failed]}
    "
    with_import_message(resource_import_textfile) do |res|
      res.error_msg = msg
      res.extraparams = "{'not_read' => true}"
    end
  end

  def split_by_semicolon(str)
    str.to_s.gsub(/；/, ';').split(/;/)
  end
end
EnjuTrunk::ResourceAdapter::Base.add(ResourceImport)

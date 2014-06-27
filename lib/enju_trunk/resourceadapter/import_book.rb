# -*- encoding: utf-8 -*-
module EnjuTrunk
  module ImportBook
    SERIES_REQUIRE_COLUMNS = %w(
      series.original_title
      series.series_statement_identifier
      series.issn
    )
    BOOK_REQUIRE_COLUMNS = %w(
      book.original_title
      book.isbn
      book.identifier
    )
    BOOK_HEADER_ROW = 1
    BOOK_DATA_ROW   = 2

    # 対象となる書誌種別がシリーズでないときに
    # シート上のシリーズ情報を完全に無視する(true)
    # または無視せずに適用する(false)
    def self.strict_series_statement_binding?
      false
    end

    # manifestations.split_by_typeがfalseのとき
    # ヘッダーにmanifestation_typeが入っている必要がある
    def check_book_header_has_manifestation_type(sheet)
      return if sheet.field_index('book.item_identifier')
      return if SystemConfiguration.get('manifestations.split_by_type')
      if sheet.field_index('book.manifestation_type').nil?
        raise I18n.t('resource_import_textfile.error.head_require_manifestation_type')
      end
    end

    # ヘッダ行に必須カラムがあることをチェックする
    def check_book_header_has_necessary_field(sheet)
      return if sheet.field_index('book.item_identifier')

      is_series = sheet.manifestation_type &&
        !sheet.manifestation_type.is_book?

      check_book_row(sheet, is_series, 'head_is_blank') do |check_columns|
        sheet.include_any?(check_columns)
      end
    end

    # データ行に必須カラムの値があることをチェックする
    def check_book_data_has_necessary_field(datas, sheet, is_series)
      check_book_row(sheet, is_series, 'cell_is_blank') do |check_columns|
        sheet.filled_any?(datas, check_columns)
      end
    end

    def check_book_row(sheet, is_series, errmsg_key)
      if is_series
        unless yield(SERIES_REQUIRE_COLUMNS) && yield(BOOK_REQUIRE_COLUMNS)
          series_field_names = SERIES_REQUIRE_COLUMNS.map {|c| sheet.field_name(c) }
          book_field_names = BOOK_REQUIRE_COLUMNS.map {|c| sheet.field_name(c) }
          raise I18n.t("resource_import_textfile.error.series.#{errmsg_key}",
                       series_fields: series_field_names.join(I18n.t('page.list_delimiter')),
                       series: I18n.t('resource_import_textfile.series'),
                       book_fields: book_field_names.join(I18n.t('page.list_delimiter')),
                       book: I18n.t('resource_import_textfile.book'))
        end
      else
        unless yield(BOOK_REQUIRE_COLUMNS)
          field_names = BOOK_REQUIRE_COLUMNS.map {|c| sheet.field_name(c) }
          raise I18n.t("resource_import_textfile.error.book.#{errmsg_key}",
                       fields: field_names.join(I18n.t('page.list_delimiter')))
        end
      end
    end

    # シートの項目値から書誌種別を導出する
    def data_manifestation_type(datas, sheet, manifestation)
      return if SystemConfiguration.get('manifestations.split_by_type')

      data_manifestation_type = sheet.field_data(datas, 'book.manifestation_type')
      manifestation_type = manifestation.manifestation_type if manifestation

      if data_manifestation_type == '' ||
          data_manifestation_type.nil? && manifestation_type.nil?
        raise I18n.t('resource_import_textfile.error.cell_require_manifestation_type')
      end

      if data_manifestation_type
        manifestation_type = ManifestationType.find_by_name(data_manifestation_type)
        unless manifestation_type
          raise I18n.t('resource_import_textfile.error.wrong_manifestation_type',
                       manifestation_type: data_manifestation_type)
        end
      end

      manifestation_type
    end

    def check_book_datas_has_necessary_field(datas, sheet, item, manifestation, manifestation_type)
      # すでに書誌情報または所蔵情報を特定できていればOK
      return if item || manifestation

      # 書誌情報を特定する情報(必要に応じて所蔵情報を生成できる情報)が含まれているか確認
      check_book_data_has_necessary_field(datas, sheet, manifestation_type.is_series?)
    end

    def check_duplicate_item_identifier(sheet)
      col = sheet.field_index('book.item_identifier')
      return unless col

      item_identifiers = {}
      sheet.each_row do |row|
        item_identifier = row[col]
        next unless item_identifier
        next if item_identifier.blank?
        item_identifiers[item_identifier] ||= 0
        item_identifiers[item_identifier] += 1
      end

      duplicates = []
      item_identifiers.each do |item_identifier, count|
        next if count == 1
        duplicates << item_identifier
      end

      if duplicates.present?
        raise I18n.t('resource_import_textfile.error.duplicate_item_identifier', :item_identifier => duplicates.join(','))
      end
    end

    def book_header_has_out_of_manage(sheet)
      field_names = Manifestation.output_column_spec.keys.
        reject {|key| /\Aarticle\./ =~ key }.
        map {|key| sheet.field_name(key) }
      unknown = sheet.field.keys.
        reject {|name| field_names.include?(name) }
      unless unknown.blank?
        logger.info " header has column that is out of manage"
        return I18n.t('resource_import_textfile.message.out_of_manage', :columns => unknown.join(', '))
      end
      return ''
    end

    def process_book_data(import_textresult, datas, sheet, textfile, numbering, auto_numbering, not_set_serial_number, external_resource)
      manifestation = series_statement = item = nil
      error_msgs = []

      # 所蔵、シリーズ、書誌を特定する
      item, item_identify_status = identify_item(datas, sheet)
      series_statement, series_statement_identify_status = identify_series_statement(datas, sheet)
      manifestation, manifestation_identify_status = identify_manifestation(datas, sheet)

      logger.debug "  record identify status: item:#{item_identify_status} manifestation:#{manifestation_identify_status} series_statement:#{series_statement_identify_status}"

      if item_identify_status == :not_found &&
          !SystemConfiguration.get('import_manifestation.force_create_item')
        # 記述されていた所蔵情報IDが登録されていない
        raise I18n.t('resource_import_textfile.error.unknown_item_identifier')
      end

      if manifestation && item &&
          item.manifestation != manifestation
        logger.debug "  identified manifestation != identified item.manifestation"
        # シート上のmanifestation-itemの組み合わせがDB上の状態と合致しない
        if !SystemConfiguration.get('import_manifestation.exchange_manifestation')
          raise I18n.t('resource_import_textfile.error.unexpected_item')
        else
          raise NotImplementedError
        end
      end

      if manifestation && series_statement &&
          manifestation.series_statement &&
          manifestation.series_statement != series_statement
        logger.debug "  identified manifestation.series_statement != identified series_statement"
        # シート上のmanifestation-series_statementの組み合わせがDB上の状態と合致しない
        if !SystemConfiguration.get('import_manifestation.exchange_series_statement')
          raise I18n.t('resource_import_textfile.error.unexpected_series_statement')
        else
          raise NotImplementedError
        end
      end

      # 削除指定があったとき、
      # 明示された情報により特定されたレコードを削除してこの行の処理を終える
      if fix_boolean(sheet.field_data(datas, 'book.del_flg'), {mode: 'delete'})
        if item && sheet.field_data(datas, 'book.item_identifier').blank?
          raise I18n.t('resource_import_textfile.error.delete_requre_item_identifier')
        end
        if item.blank? && manifestation.blank? && series_statement.blank?
          raise I18n.t('resource_import_textfile.error.failed_delete_not_find')
        end

        delete_record(import_textresult, item, manifestation, series_statement)
        import_textresult.error_msg = error_msgs.join('<br />')
        return
      end

      # シートの項目値から抽出できなかった部分を
      # レコードの関係から補完する
      if manifestation.nil? && item
        manifestation = item.manifestation
      end
      if manifestation.nil? && manifestation_identify_status == :too_many
        error_msgs << I18n.t('resource_import_textfile.error.book.exist_multiple_same_manifestations')
      end

      if series_statement.nil? && series_statement_identify_status == :empty_cond &&
          manifestation && manifestation.series_statement
        series_statement = manifestation.series_statement
      end
      if series_statement.nil? && series_statement_identify_status == :too_many
        error_msgs << I18n.t('resource_import_textfile.error.series.exist_multiple_same_manifestations')
      end
      logger.debug "  record find status: item:#{item.present?} manifestation:#{manifestation.present?} series_statement:#{series_statement.present?} root_manifestation:#{series_statement.try(:root_manifestation).present?}"

      manifestation_type = sheet.manifestation_type
      manifestation_type = data_manifestation_type(datas, sheet, manifestation) unless manifestation_type
      logger.debug "  manifestation_type=#{manifestation_type.try(:name)}"

      check_book_datas_has_necessary_field(
        datas, sheet, item, manifestation, manifestation_type)
      manifestation = update_or_create_manifestation(
        datas, sheet,
        manifestation_type, manifestation,
        not_set_serial_number, series_statement,
        error_msgs, external_resource)

      if series_statement
        # root manifestation
        update_or_create_manifestation(
          datas, sheet,
          manifestation_type, series_statement.root_manifestation,
          not_set_serial_number, series_statement,
          error_msgs, external_resource, true)
      end

      item = update_or_create_item(
        datas, sheet, textfile, numbering, auto_numbering, manifestation, item, error_msgs)

      import_textresult.manifestation = manifestation
      import_textresult.item = item
      manifestation.index
      manifestation.series_statement.index if manifestation.series_statement

      import_textresult.error_msg = error_msgs.join('<br />')

      if false # DO NOT AUTO RETAIN import_textresult.item.manifestation.next_reserve
        current_user = User.where(:username => 'admin').first
        msg = []
        if import_textresult.item.manifestation.next_reserve and import_textresult.item.item_identifier
          import_textresult.item.retain(current_user) if import_textresult.item.available_for_retain?
          msg << I18n.t('resource_import_file.reserved_item',
            :username => import_textresult.item.reserve.user.username,
            :user_number => import_textresult.item.reserve.user.user_number)
        end
        import_textresult.error_msg = msg.join("\s\n")
      end
    end

    def update_or_create_manifestation(datas, sheet, manifestation_type, manifestation, not_set_serial_number, series_statement, error_msgs, external_resource, is_root = false)
      if is_root
        # root_manifestationのための処理を行う
        field = 'root'
        return nil unless series_statement
        return nil unless manifestation # 既存のmanifestationが引数で与えられた場合のみ(つまり更新のみ)処理する
      else
        # 一般manifestationのための処理を行う
        field = 'book'
      end

      isbn = sheet.field_data(datas, "#{field}.isbn").try(:to_s) unless is_root

      if manifestation
        mode = 'edit'

      else
        mode = 'create'

        unless is_root
          if sheet.field_data(datas, 'book.original_title').blank? # タイトル未入力で登録しようとしていないか確認
            raise I18n.t('resource_import_textfile.error.book.no_title')
          end

          nbn = sheet.field_data(datas, "#{field}.nbn").try(:to_s) #ndl:JPNO,nacsis:NBN
          if external_resource == "nacsis"
            ncid = sheet.field_data(datas, "#{field}.nacsis_identifier").try(:to_s)
          end
          if isbn || ncid || nbn
            manifestation = import_from_external_resource(isbn, ncid, nbn, external_resource)
          end
        end

        manifestation = Manifestation.new unless manifestation
      end

      if series_statement &&
          !manifestation_type.is_series? &&
          self.class.strict_series_statement_binding?
        # 書誌種別がシリーズでなければ、
        # 特定されたシリーズ情報があっても無視する
        series_statement = nil
        error_msgs << I18n.t('resource_import_textfile.error.unsuitable_manifestation_type')

      elsif !is_root
        if series_statement || manifestation_type.is_series?
          series_statement =
            update_or_create_series_statement(
              datas, sheet, manifestation, series_statement)
        elsif !manifestation_type.is_series? &&
            sheet.filled_any?(datas, Manifestation.series_output_columns)
          # シリーズを新規作成する必要があるが
          # 書誌の資料種別がシリーズ向けではない)
          error_msgs << I18n.t('resource_import_textfile.error.unsuitable_manifestation_type')
        end
      end

      manifestation.during_import = true
      manifestation.manifestation_type = manifestation_type
      unless is_root
        manifestation.series_statement = series_statement if series_statement
        manifestation.periodical = true if manifestation.series_statement && manifestation.series_statement.periodical
        manifestation.isbn = isbn.to_s unless isbn.nil?
      end

      if not_set_serial_number
        serial_number_overwrite = :deny_overwrite
      else
        serial_number_overwrite = :allow_overwrite
      end

      # root/一般 manifestation
      set_attributes(manifestation, datas, sheet, {
        carrier_type: [
          "#{field}.carrier_type",
          [:set_data, mode, CarrierType, default: 'print'],
        ],
        jpn_or_foreign: [
          "#{field}.jpn_or_foreign",
          [:check_jpn_or_foreign], [:set_nil_when_blank]
        ],
        pub_date: ["#{field}.pub_date", [:to_s]],
        country_of_publication: [
          "#{field}.country_of_publication",
          [:set_data, mode, Country, default: 'unknown'],
        ],
        place_of_publication: ["#{field}.place_of_publication", [:to_s]],
        edition_display_value: ["#{field}.edition_display_value"],
        volume_number_string: ["#{field}.volume_number_string", [:to_s]],
        issue_number_string: ["#{field}.issue_number_string", [:to_s]],
        serial_number_string: [
          "#{field}.serial_number_string",
          [:to_s], [serial_number_overwrite]
        ],
        serial_number: [
          "#{field}.serial_number",
          [:check_data_is_integer], [serial_number_overwrite]
        ],
        price: ["#{field}.price", [:check_data_is_numeric]],
        access_address: ["#{field}.access_address", [:to_s]],
        repository_content: [
          "#{field}.repository_content", [:fix_boolean, mode: mode]
        ],
        required_role: [
          "#{field}.required_role",
          [:set_data, mode, Role, default: 'Guest']
        ],
        except_recent: [
          "#{field}.except_recent", [:fix_boolean, mode: mode]
        ],
        description: ["#{field}.description", [:to_s]],
        supplement: ["#{field}.supplement", [:to_s]],
        use_license: [
          "#{field}.use_license",
          [:set_data, mode, UseLicense, check_column: :id]
        ],
      })

      # 一般 manifestation
      set_attributes(manifestation, datas, sheet, {
        original_title: ["#{field}.original_title", [:to_s]],
        title_transcription: ["#{field}.title_transcription", [:to_s]],
        title_alternative: ["#{field}.title_alternative", [:to_s]],
        frequency: [
          "#{field}.frequency",
          [:set_data, mode, Frequency,
            default: '不明', check_column: :display_name],
        ],
        dis_date: ["#{field}.dis_date", [:to_s]],
        lccn: ["#{field}.lccn", [:to_s]],
        marc_number: ["#{field}.marc_number", [:to_s]],
        ndc: ["#{field}.ndc", [:to_s]],
        start_page: ["#{field}.start_page", [:to_s], [:set_nil_when_blank]],
        end_page: ["#{field}.end_page", [:to_s], [:set_nil_when_blank]],
        height: ["#{field}.height", [:check_data_is_numeric]],
        width: ["#{field}.width", [:check_data_is_numeric]],
        depth: ["#{field}.depth", [:check_data_is_numeric]],
        acceptance_number: [
          "#{field}.acceptance_number", [:check_data_is_integer]
        ],
        note: ["#{field}.note", [:to_s]],
        missing_issue: [
          "#{field}.missing_issue", [:to_i], [:set_nil_when_blank]],
        identifier: ["#{field}.identifier", [:to_s]],
        wrong_isbn: ["#{field}.wrong_isbn", [:to_s]],
        nbn: ["#{field}.nbn", [:to_s]],
        size: ["#{field}.size", [:to_s]],
      }) unless is_root

      manifestation.save!

      if mode == "create"
        logger.info "created new #{is_root ? 'root ' : ''}manifestation \##{manifestation.id} title:#{manifestation.original_title}"
        update_summary(:manifestation_imported)
      else
        logger.info "updated #{is_root ? 'root ' : ''}manifestation \##{manifestation.id} title:#{manifestation.original_title}"
        update_summary(:manifestation_found)
      end

      manifestation.series_statement = series_statement if series_statement

      update_manifestation_agents(sheet, datas, field, manifestation, error_msgs)
      update_manifestation_subjects(sheet, datas, field, manifestation, error_msgs)
      update_manifestation_languages(sheet, datas, field, manifestation, error_msgs)
      update_manifestation_classifications(sheet, datas, field, manifestation, error_msgs)

      # manifestation_titles
      records = build_associated_records(sheet, datas, manifestation, :work_has_titles, {
        title: ["#{field}.other_title"],
        title_type: ["#{field}.other_title_type", TitleType, :name],
      })
      manifestation.work_has_titles = records unless records.nil?

      # identifiers
      unless is_root
        records = build_associated_records(sheet, datas, manifestation, :identifiers, {
          body: ["#{field}.other_identifier"],
          identifier_type: ["#{field}.other_identifier_type", IdentifierType, :id],
        })
        manifestation.identifiers = records unless records.nil?
      end

      # themes
      # TODO: enju_trunk_themeに処理を移す
      if defined?(EnjuTrunkTheme) && !is_root
        records = build_associated_records(sheet, datas, manifestation, :themes, {
          name: ["#{field}.theme"],
          publish: ["#{field}.theme_publish"],
        })
        manifestation.themes = records unless records.nil?
      end

      # manifestation_extexts / manifestation_exinfos
      unless is_root
        book_columns = Manifestation.book_output_columns

        extexts = {}
        book_columns.grep(/^#{Regexp.quote(field)}\.manifestation_extext\..+$/) do |field_key|
          data = sheet.field_data(datas, field_key)
          extexts[key] = data if data
        end
        if extexts.present?
          manifestation.manifestation_extexts = ManifestationExtext.add_extexts(extexts, manifestation.id)
        end

        exinfos = {}
        book_columns.grep(/^#{Regexp.quote(field)}\.manifestation_exinfo\..+$/) do |field_key|
          data = sheet.field_data(datas, field_key)
          extexts[key] = data if data
        end
        if exinfos.present?
          manifestation.manifestation_exinfos = ManifestationExinfo.add_exinfos(exinfos, manifestation.id)
        end
      end

      if series_statement && !is_root
        manifestation.series_statement = series_statement
      end
      manifestation
    end

    def update_manifestation_agents(sheet, datas, field, manifestation, error_msgs)
      create_new = SystemConfiguration.get("add_only_exist_agent") == true

      [
        ["#{field}.creator", :creators=, :creates],
        ["#{field}.publisher", :publishers=, :produces],
        ["#{field}.contributor", :contributors=, :realizes],
      ].each do |field_key, writer, assoc_name|
        if Manifestation.separate_output_columns?
          writer = "#{assoc_name}="

          name_fk = field_key
          tran_fk = "#{field_key}_transcription"
          type_fk = "#{field_key}_type"

          agent_data = sheet.field_data_set(datas, [name_fk, tran_fk, type_fk])
          next if agent_data.nil?

          atype_cls = (assoc_name.to_s.classify + 'Type').constantize
          atype_method = assoc_name.to_s.singularize + '_type_id='

          assoc_records = []
          agent_data.each do |adata|
            agent = Agent.add_agent(adata[name_fk], adata[tran_fk], create_new: create_new)
            next if agent.blank?

            record = manifestation.__send__(assoc_name).build
            record.agent = agent
            if type_id = adata[type_fk]
              if type = atype_cls.where(id: type_id).first
                record.__send__(atype_method, type)
              end
            end
            assoc_records << record
          end

        else
          value = sheet.field_data(datas, field_key)
          next if value.nil?
          assoc_records = Agent.add_agents(value, nil, create_new: create_new)
        end

        if assoc_name == :realizes
          #TODO update contributor position withou destroy_all
          manifestation.contributors.destroy_all unless manifestation.contributors.empty?
        end
        manifestation.__send__(writer, assoc_records)
      end
    end

    def update_manifestation_languages(sheet, datas, field, manifestation, error_msgs)
      if Manifestation.separate_output_columns?
        records = build_associated_records(sheet, datas, manifestation, :work_has_languages, {
          language_id: ["#{field}.language", Language, :name],
          language_type: ["#{field}.language_type", LanguageType, :name, allow_blank: true],
        })
        manifestation.work_has_languages = records unless records.nil?

      else
        languages_list   = []
        languages_string = sheet.field_data(datas, "#{field}.language")
        languages        = languages_string.nil? ? nil : split_by_semicolon(languages_string).uniq.compact
        if languages.blank?
          languages_list << Language.where(:name => 'Japanese').first
        else
          languages.each do |language|
            next if language.blank?
            obj = Language.where(:name => language).first
            if obj.nil?
              raise I18n.t('resource_import_textfile.error.wrong_data',
                            :field => sheet.field_name("#{field}.language"),
                            :data => language)
            else
              languages_list << obj
            end
          end
        end
        manifestation.languages = languages_list unless languages_list.blank?
      end
    end

    def update_manifestation_subjects(sheet, datas, field, manifestation, error_msgs)
      if Manifestation.separate_output_columns?
        subject_data = sheet.field_data_set(
          datas, %W(#{field}.subject #{field}.subject_transcription))
        if subject_data.nil?
          subject_list = subject_trans_list = nil

        else
          # TODO: Subject.import_subjectsが配列を受け入れるようにする
          dlm = ';'
          subject_list = []
          subject_trans_list = []
          subject_data.each do |adata|
            subject_list << adata["#{field}.subject"]
            subject_trans_list << adata["#{field}.subject_trans_list"]
          end
          subject_list = subject_list.join(dlm)
          subject_trans_list = subject_trans_list.join(dlm)
        end

      else
        subject_list = sheet.field_data(datas, "#{field}.subject")
        subject_trans_list = nil
      end

      unless subject_list.nil?
        subjects = Subject.import_subjects(subject_list, subject_trans_list)
        manifestation.subjects = subjects
      end
    end

    def update_manifestation_classifications(sheet, datas, field, manifestation, error_msgs)
      return unless field == 'book'

      classification_field = "#{field}.classification"
      classification_type_field = "#{field}.classification_type"
      classification_attrs = nil

      if Manifestation.separate_output_columns?
        classification_attrs = sheet.field_data_set(datas,
          [classification_field, classification_type_field])

      else
        return unless sheet.field_index(classification_field)

        value = sheet.field_data(datas, classification_field) || ''
        classification_attrs = split_by_semicolon(value).map do |category|
          {classification_field => category}
        end
      end
      return if classification_attrs.nil?

      classification_list = []

      classification_attrs.each do |hash|
        type = hash[classification_type_field] || 'ndc9'
        category = hash[classification_field]
        next if category.blank?

        ct = ClassificationType.where(name: type).first
        unless ct
          error_msgs << I18n.t(
            'resource_import_textfile.error.unknown_classification_type',
            type: type)
          next
        end

        c = Classification.where(category: category).
          where(classification_type_id: ct).first
        unless c
          error_msgs << I18n.t(
            'resource_import_textfile.error.unknown_classification',
            type: type, category: category)
          next
        end

        classification_list << c
      end

      manifestation.classifications = classification_list
    end

    def import_from_external_resource(isbn, ncid, nbn, external_resource)
      manifestation = nil

      if ncid.present?
        manifestation = NacsisCat.create_manifestation_from_ncid(ncid)

      elsif nbn.present?
        #NBNインポートの選択
        if external_resource == "nacsis"
          manifestation = NacsisCat.create_manifestation_from_nbn(nbn)
        else
          manifestation = Manifestation.import_from_ndl_search(jpno: nbn)
        end

      elsif isbn.present?
        begin
          #ISBNインポート先の選択
          if external_resource == "nacsis"
            manifestation = NacsisCat.create_manifestation_from_isbn(isbn)
          else
            manifestation = Manifestation.import_isbn(isbn)
          # raise I18n.t('resource_import_textfile.error.book.wrong_isbn') unless manifestation
          end
        rescue EnjuNdl::InvalidIsbn
          raise I18n.t('resource_import_textfile.error.book.wrong_isbn')
        rescue EnjuNdl::RecordNotFound
          raise I18n.t('resource_import_textfile.error.book.record_not_found')
        end
      end

      #manifestation.external_catalog = 1 if manifestation
      return manifestation
    end

    def identified_result(cand)
      obj = nil
      if cand.size == 1
        obj = cand.first
        res = :identified
      elsif cand.size == 0
        res = :not_found
      else
        res = :too_many
      end

      [obj, res]
    end

    # 所蔵IDにより対応する所蔵レコードを特定する
    def identify_item(datas, sheet)
      Rails.logger.debug "identify_item"

      item_identifier = sheet.field_data(datas, 'book.item_identifier')
      unless item_identifier.present?
        res = [nil, :blank_identifier]
        Rails.logger.debug "item #{res[1]}"
        return res
      end

      cand = Item.where(item_identifier: item_identifier.to_s).order("created_at asc").all
      res = identified_result(cand)
      Rails.logger.debug "item #{res[1]}"

      res
    end

    # 書誌ID、ISBN、または以下に挙げる全項目の一致によりシリーズ情報を特定する
    #  * タイトル
    #  * 発行日
    #  * 作者
    #  * 出版者
    #  * シリーズ名(指定された場合のみ)
    def identify_manifestation(datas, sheet)
      Rails.logger.debug "identify_manifestation"

      scope = Manifestation.scoped
      scope = scope.readonly(false)

      identifier = sheet.field_data(datas, 'book.identifier')
      if identifier.present?
        cand = scope.where(identifier: identifier.to_s).all
        # 書誌IDの指定があるときには、書誌IDのみから特定する
        res = identified_result(cand)
        Rails.logger.debug "manifestation #{res[1]}"
        return res
      end

      isbn = sheet.field_data(datas, 'book.isbn')
      if isbn.present?
        # ISBNにより単一レコードを抽出できるなら
        # 書誌を特定できたものとみなす
        cand = scope.where(isbn: isbn.to_s).all
        res = identified_result(cand)
        if res[1] == :identified
          Rails.logger.debug "manifestation #{res[1]}"
          return res
        end
      end

      scope = scope.joins(:creates).  # creators
        joins('INNER JOIN agents creators_agents ON creators_agents.id = creates.agent_id')
      scope = scope.joins(:produces). # publishers
        joins('INNER JOIN agents publishers_agents ON publishers_agents.id = produces.agent_id')

      check_procs = []
      {
        original_title: 'book.original_title',
        pub_date: 'book.pub_date',
        creators: 'book.creator',
        publishers: 'book.publisher',
        series_title: 'series.original_title',
      }.each do |attr_name, field_key|

        case attr_name
        when :creators, :publishers
          if Manifestation.separate_output_columns?
            fds = sheet.field_data_set(datas, [field_key])
            field_data = fds.blank? ? nil : fds.map {|h| h[field_key] }
          else
            fd = sheet.field_data(datas, field_key)
            field_data = fd.blank? ? nil : split_by_semicolon(fd)
          end

        else
          field_data = sheet.field_data(datas, field_key)
        end

        if field_data.nil? && attr_name != :series_title ||
            !field_data.nil? && field_data.blank?
          # データ中に書誌特定条件が指定されていない
          res = [nil, :empty_cond]
          Rails.logger.debug "manifestation #{res[1]}"
          return res
        end

        case attr_name
        when :creators, :publishers
          check_procs << proc do |record|
            record_agent_names = record.__send__(attr_name).pluck(:full_name).sort
            record_agent_names == field_data.sort
          end
          scope = scope.where(:"#{attr_name}_agents" => {full_name: field_data})

        when :series_title
          if field_data.present?
            scope = scope.joins(:series_statement)
            scope = scope.where(series_statements: {original_title: field_data})
          end

        else
          scope = scope.where(attr_name => field_data.to_s)
        end
      end

      records = scope.uniq.all
      Rails.logger.debug "manifestation candidates #{records.count}"
      check_procs.each do |check|
        records = records.select(&check)
      end

      res = identified_result(records)
      Rails.logger.debug "manifestation #{res[1]}"

      res
    end

    # シリーズIDまたはISSNの一致によりシリーズ情報を特定する
    def identify_series_statement(datas, sheet)
      Rails.logger.debug "identify_series_statement"
      scope = SeriesStatement.scoped
      cand = nil

      if series_identifier = sheet.field_data(datas, 'series.series_statement_identifier')
        cand = scope.where(series_statement_identifier: series_identifier.to_s).all
      elsif issn = sheet.field_data(datas, 'series.issn')
        cand = scope.where(issn: issn.to_s).all
      end

      if cand
        res = identified_result(cand)
      else
        # データ中にシリーズ特定条件が指定されていない
        res = [nil, :empty_cond]
      end
      Rails.logger.debug "series_statement #{res[1]}"
      res
    end

    # series_statementが与えられればそれを更新し、
    # 与えられければ(nilならば)新規に作成する。
    # 更新時には与えられたseries_statementを、
    # 新規作成時には新しいseries_statementを返す。
    def update_or_create_series_statement(datas, sheet, manifestation, series_statement)
      if series_statement
        mode = 'edit'
      else
        mode = 'create'
        series_statement = SeriesStatement.new
      end

      set_attributes(series_statement, datas, sheet, {
        original_title: [
          'series.original_title', [:to_s]
        ],
        title_transcription: [
          'series.title_transcription', [:to_s]
        ],
        periodical: [
          'series.periodical', [:fix_boolean, mode: mode]
        ],
        series_statement_identifier: [
          'series.series_statement_identifier', [:to_s]
        ],
        issn: ['series.issn', [:to_s]],
        note: ['series.note', [:to_s]],
        sequence_pattern: [
          'series.sequence_pattern',
          [:set_data, mode, SequencePattern, can_blank: true],
          [:set_nil_when_blank],
        ],
        publication_status: [
          'series.publication_status',
          [:set_data, mode, PublicationStatus, can_blank: true],
          [:set_nil_when_blank],
        ],
      })

      if series_statement.periodical == true &&
          series_statement.root_manifestation.nil?
        root_manifestation =
          series_statement.root_manifestation =
          series_statement.initialize_root_manifestation
      end
      series_statement.save!

      if mode == 'create'
        logger.info "created new series_statement \##{series_statement.id} title:#{series_statement.original_title}"
      else
        logger.info "updated series_statement \##{series_statement.id} title:#{series_statement.original_title}"
      end

      series_statement.manifestations << root_manifestation if root_manifestation
      series_statement.index

      series_statement
    end

    def update_or_create_item(datas, sheet, textfile, numbering, auto_numbering, manifestation, item, error_msgs)
      if item
        mode = 'edit'
        item.manifestation.try(:reload) # ActiveRecord::StaleObjectError回避

      else
        unless sheet.field_index('book.item_identifier') || auto_numbering
          error_msgs << I18n.t('resource_import_textfile.message.without_item')
          return item
        end
        item = Item.new
        mode = 'create'
      end

      # 所蔵情報IDの設定
      if item.item_identifier
        # noop
        # NOTE:
        # 所蔵情報の特定は所蔵ID(item_identifier)により行われている。
        # よってitem.item_identifierに値があるのならば
        # 改めてシートの項目値をもとに処理する必要がない。

      elsif item_identifier = sheet.field_data(datas, 'book.item_identifier')
        item.item_identifier = item_identifier.to_s

      elsif auto_numbering
        begin
          create_item_identifier = Numbering.do_numbering(numbering.name)
        end while Item.where(item_identifier: create_item_identifier).exists?
        item.item_identifier = create_item_identifier
      end

      unless item.item_identifier
        logger.info I18n.t("resource_import_textfile.error.no_item_identifier")
        return
      end

      item.manifestation_id = manifestation.id

      set_attributes(item, datas, sheet, {
        accept_type: [
          'book.accept_type',
          [:set_data, mode, AcceptType, can_blank: true, check_column: :display_name],
          [:set_nil_when_blank],
        ],
        acquired_at_string: ['book.acquired_at', [:to_s]],
        checkout_type: [
          'book.checkout_type', [:set_data, mode, CheckoutType, default: 'book']],
        retention_period: [
          'book.retention_period',
          [:set_data, mode, RetentionPeriod, default: '永年', check_column: :display_name],
        ],
        call_number: ['book.call_number', [:to_s]],
        price: ['book.item_price', [:check_data_is_integer]],
        url: ['book.url', [:to_s]],
        include_supplements: [
          'book.include_supplements', [:fix_boolean, mode: mode],
        ],
        note: ['book.item_note', [:to_s]],
        required_role: [
          'book.required_role', [:set_data, mode, Role, default: 'Guest'],
        ],
        non_searchable: [
          'book.non_searchable', [:fix_boolean, mode: mode]],
        rank: [
          'book.rank',
          [:fix_rank, manifestation: manifestation, mode: mode],
          [:set_nil_when_blank],
        ],
        required_role: [
          'book.item_required_role',
          [:set_data, mode, Role, default: 'Guest'],
        ],
      })

      # use_restriction
      use_restriction = fix_use_restriction(sheet.field_data(datas, 'book.use_restriction'))
      use_restriction ||= item.use_restriction
      item.use_restriction_id = use_restriction.id if use_restriction

      # library and shelf
      library = set_library(sheet.field_data(datas, 'book.library'), textfile.user)
      shelf = set_shelf(sheet.field_data(datas, 'book.shelf'), textfile.user, library)
      item.library_id = library.id unless library.nil?
      item.shelf = shelf unless shelf.nil?

      # bookstore
      bookstore_name = sheet.field_data(datas, 'book.bookstore')
      if bookstore_name == ""
        item.bookstore = nil
      else
        bookstore = Bookstore.import_bookstore(bookstore_name) rescue nil
        item.bookstore = bookstore unless bookstore.nil?
      end

      # circulation_status and remove_reason
      cstatus_field_name, cstatus_field_data = sheet.field_name_and_data(datas, 'book.circulation_status')
      rreason_field_name, rreason_field_data = sheet.field_name_and_data(datas, 'book.remove_reason')

      cstatus = set_data(cstatus_field_data, cstatus_field_name,
        mode, CirculationStatus, {default: 'In Process'})
      rreason = set_data(rreason_field_data, rreason_field_name,
        mode, RemoveReason, {can_blank: true, check_column: :display_name})

      item.circulation_status = cstatus unless cstatus.nil?
      if rreason
        item.remove_reason = rreason
        if cstatus_field_data.nil?
          item.circulation_status = CirculationStatus.where(:name => "Removed").first
        end
        item.removed_at = Time.zone.now
      else
        if rreason_field_data == ''
          item.circulation_status = CirculationStatus.where(:name => "In Process").first if cstatus.nil?
          item.remove_reason = nil
        end
      end

      item.save!

      if mode == 'create'
        logger.info "created new item \##{item.id} identifier:#{item.item_identifier}"
        update_summary(:item_imported)
      else
        logger.info "updated item \##{item.id} identifier:#{item.item_identifier}"
        update_summary(:item_found)
      end

      item.agents << shelf.library.agent if mode == 'create'
      item.manifestation = manifestation
      unless item.remove_reason.nil?
        if item.reserve
          item.reserve.revert_request rescue nil
        end
      end

      item
    end

    # 一組の出力カラムのセット(たとえば言語と言語タイプ)から
    # 一連のレコードの配列を生成する。
    #
    # 例:
    #
    #   build_associated_records(sheet, datas, manifestation, :work_has_languages, {
    #     language_id: ['book.language', Language, :name],
    #     language_type_id: ['book.language_type', LanguageType, :name, allow_blank: true],
    #   })
    #   #=> [aWorkHasLanguage, ...]
    def build_associated_records(sheet, datas, record, assoc_name, spec)
      field_keys = spec.values.map(&:first)
      target_data = sheet.field_data_set(datas, field_keys)
      return nil if target_data.nil?

      assoc_records = []

      target_data.each do |field_set|
        next if field_set.all? {|fk, fv| fv.blank? } # 全部項目が空欄

        attrs = {}
        spec.each do |attr_name, (field_key, model_class, key, opts)|
          opts ||= {}
          field_data = field_set[field_key]
          field_name = sheet.suffixed_field_name(field_key, field_set.suffix)

          if field_data.blank? && !opts[:allow_blank]
            raise I18n.t('resource_import_textfile.error.wrong_data',
                          field: field_name, data: field_data)
          elsif field_data.blank?
            obj = nil
          elsif model_class
            obj = model_class.where(key => field_data).first
            unless obj
              obj = model_class.new {|r| r[key] = field_data }
            end
          else
            obj = field_data
          end

          if obj.blank? && opts[:default]
            obj = opts[:default]
          end

          if obj.blank? && !opts[:allow_blank]
            raise I18n.t('resource_import_textfile.error.wrong_data',
                          field: field_name, data: field_data)
          end

          attrs[attr_name] = obj
        end

        assoc_records << record.__send__(assoc_name).build do |assoc_record|
          attrs.each do |attr_name, value|
            assoc_record.__send__("#{attr_name}=", value)
          end
          assoc_record.save!
        end
      end

      assoc_records
    end

    def fix_use_restriction(cell, options = {:mode => 'input'})
      if options[:mode] == 'delete'
        return nil if cell.nil? or cell.blank?
      end
      if cell.nil? or cell.blank? or cell.upcase == 'FALSE' or cell == ''
        if options[:mode] == 'input'
          return UseRestriction.where(:name => 'Limited Circulation, Normal Loan Period').first
        else
          return nil
        end
      end
      return UseRestriction.where(:name => 'Not For Loan').first
    end

    def fix_rank(cell, options = {:manifestation => nil, :mode => 'create'})
      case cell
      when I18n.t('item.original')
        #if manifestation.items.map {|i| i.rank.to_i }.compact.include?(0)
        #  raise I18n.t('resource_import_textfile.error.book.has_original', :data => cell)
        #else
        return 0
        #end
      when I18n.t('item.copy')
        return 1
      when I18n.t('item.spare')
        return 2
      when ""
        return nil
      when nil
        if options[:mode] == 'create'
          if options[:manifestation].items and options[:manifestation].items.size > 0
            if options[:manifestation].items.map {|i| i.rank.to_i }.compact.include?(0)
              return 1
            end
          end
          return 0
        else
          return nil
        end
      else
        raise I18n.t('resource_import_textfile.error.book.wrong_rank', :data => cell)
      end
    end

    def set_attributes(record, datas, sheet, opts)
      opts.each do |attr_name, (field_key, *convs)|
        set_nil_when_blank = false
        allow_overwrite = true
        value = sheet.field_data(datas, field_key)
        convs.each do |conv, *conv_args|
          case conv
          when :set_nil_when_blank
            set_nil_when_blank = true
          when :allow_overwrite
            allow_overwrite = true
          when :deny_overwrite
            allow_overwrite = false
          when :to_s
            value = value.to_s unless value.blank?
          when :to_i
            value = value.to_i unless value.blank?
          when :set_data, :check_data_is_numeric, :check_data_is_integer
            value = __send__(conv, value, sheet.field_name(field_key), *conv_args)
          else
            value = __send__(conv, value, *conv_args)
          end
        end
        unless value.nil?
          value = nil if value.blank? && set_nil_when_blank
          if allow_overwrite || record.__send__(attr_name).blank?
            record.__send__("#{attr_name}=", value)
          end
        end
      end
    end

    def set_data(field_value, filed_name, mode, model, options = {})
      obj = nil
      options[:can_blank]    = false    if options[:can_blank].nil?
      options[:check_column] = :name    if options[:check_column].nil?

      if field_value.nil?
        if options[:can_blank]
          obj = nil
        elsif mode != 'create'
          obj = nil
        else
          obj = model.where(options[:check_column] => options[:default]).first
        end
      elsif options[:can_blank] == true and field_value.blank?
        obj = nil
      else
        #obj = options[:model].where(options[:check_column] => field_value).first# rescue nil
        obj = model.where(options[:check_column] => field_value).first# rescue nil
        if obj.nil?
          raise I18n.t('resource_import_textfile.error.wrong_data',
             :field => field_name, :data => field_value)
        end
      end
      return obj
    end

    def check_data_is_integer(field_value, field_name, options = {:mode => 'create'})
      if options[:mode] == "delete"
        return nil if field_value.nil? or field_value.blank?
      end
      return nil unless field_value
      field_value = field_value.to_s.strip
      if field_value.match(/^\d*$/)
        return field_value
      elsif field_value.match(/^[0-9]+\.0$/)
        return field_value.to_i
      elsif field_value.match(/\D/)
        raise I18n.t('resource_import_textfile.error.book.only_integer',
          :field => field_name, :data => field_value)
      end
    end

    def check_data_is_numeric(field_value, field_name, options = {:mode => 'create'})
      if options[:mode] == "delete"
        return nil if field_value.nil? or field_value.blank?
      end
      return nil unless field_value
      field_value = field_value.to_s.strip
      if field_value.match(/^\d*$/)
        return field_value
      elsif field_value.match(/^[0-9]+\.0$/)
        return field_value.to_i
      elsif field_value.match(/^[0-9]*\.[0-9]*$/)
        return field_value
      else
        raise I18n.t('resource_import_textfile.error.book.only_numeric',
          :field => field_name, :data => field_value)
      end
    end

    def check_jpn_or_foreign(jpn_or_foreign)
      return nil unless jpn_or_foreign

      if jpn_or_foreign.to_s != '0' and jpn_or_foreign.to_s != '1'
        raise I18n.t('resource_import_textfile.error.book.wrong_jpn_or_foreign', :data => jpn_or_foreign)
      end

      return jpn_or_foreign
    end

    def set_library(input_library, user, options = {:mode => 'input'})
      if input_library.nil?
        if options[:mode] == 'input'
          return user.library
        else
          return nil
        end
      else
        library = Library.where(:display_name => input_library.to_s).first
        if library.nil?
          raise I18n.t('resource_import_textfile.error.book.not_exsit_library', :library => input_library)
        else
          return library
        end
      end
    end

    def set_shelf(input_shelf, user, library, options = {:mode => 'input'})
      if input_shelf.nil?
        if options[:mode] == 'input'
          if library.nil?
            return user.library.in_process_shelf
          else
            return library.in_process_shelf
          end
        else
          return nil
        end
      else
        shelf = nil
        if library.nil?
          shelf = Shelf.where(:display_name => input_shelf, :library_id => user.library.id).first rescue nil
        else
          shelf = Shelf.where(:display_name => input_shelf, :library_id => library.id).first rescue nil
        end
        if shelf.nil?
          raise I18n.t('resource_import_textfile.error.book.not_exsit_shelf', :shelf => input_shelf)
        elsif !library.shelves.include?(shelf)
          raise I18n.t('resource_import_textfile.error.book.has_not_shelf', :data => cell)
        else
          return shelf
        end
      end
    end

    def delete_record(error_msgs, item, manifestation, series_statement)
      deleted_item =
        deleted_item_identifier =
        deleted_manifestation =
        deleted_manifestation_title =
        deleted_series_statement =
        deleted_series_title = nil

      if item
        item.destroy
        deleted_item = item
        deleted_item_identifier = deleted_item.item_identifier
        logger.info "deleted item item_identifier:#{deleted_item_identifier}"
      end

      if manifestation && manifestation.items.blank?
        manifestation.destroy
        deleted_manifestation = manifestation
        deleted_manifestation_title = deleted_manifestation.original_title
        logger.info "deleted manifestation title:#{deleted_manifestation_title}"
      end

      if series_statement
        if series_statement.periodical && series_statement.manifestations.count == 1
          series_manifestation = series_statement.manifestations.first
          series_manifestation.destroy if series_manifestation.periodical_master
        end

        if series_statement.manifestations.blank?
          series_statement.destroy
          deleted_series_statement = series_statement
          deleted_series_title = deleted_series_statement.original_title
          logger.info "deleted series_statement title:#{deleted_series_title}"
        end
      end

      unless deleted_item || deleted_manifestation || deleted_series_statement
        raise I18n.t('resource_import_textfile.error.failed_delete_not_find')
      end

      msgs = []
      msgs << I18n.t('resource_import_textfile.message.deleted_item', identifier: deleted_item_identifier) if deleted_item
      msgs << I18n.t('resource_import_textfile.message.deleted_manifestation', original_title: deleted_manifestation_title) if  deleted_manifestation
      msgs << I18n.t('resource_import_textfile.message.deleted_series_statement', original_title: deleted_series_title) if deleted_series_statement

      error_msgs << "#{I18n.t('resource_import_textfile.message.deleted')} #{msgs.join(' / ')}"
    end
  end
end

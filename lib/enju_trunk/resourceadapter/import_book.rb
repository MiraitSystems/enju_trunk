# -*- encoding: utf-8 -*-
module EnjuTrunk
  module ImportBook
    SERIES_REQUIRE_COLUMNS = %w(original_title issn)
    BOOK_REQUIRE_COLUMNS   = %w(original_title isbn)
    BOOK_HEADER_ROW        = 1
    BOOK_DATA_ROW          = 2

    # ヘッダーにmanifestation_typeが入っている必要がある(manifestations.split_by_typeがfalse)とき
    def check_book_header_has_manifestation_type(field)
      return if field[I18n.t('resource_import_textfile.excel.book.item_identifier')]
      return if SystemConfiguration.get('manifestations.split_by_type')
      if field[I18n.t('resource_import_textfile.excel.book.manifestation_type')].nil?
        raise I18n.t('resource_import_textfile.error.head_require_manifestation_type')
      end
    end

    def check_book_header_has_necessary_field(field, manifestation_type)
      return if field[I18n.t('resource_import_textfile.excel.book.item_identifier')]
      require_book   = BOOK_REQUIRE_COLUMNS.map  { |column| field[I18n.t("resource_import_textfile.excel.book.#{column}")]   }
      require_series = SERIES_REQUIRE_COLUMNS.map{ |column| field[I18n.t("resource_import_textfile.excel.series.#{column}")] }
      if manifestation_type.nil? or manifestation_type.is_book?
        if require_book.reject{ |field| field.to_s.strip == "" }.empty?
          raise I18n.t('resource_import_textfile.error.book.head_is_blank')
        end
      else
        if require_series.reject{ |f| f.to_s.strip == "" }.empty? and require_book.reject{ |f| f.to_s.strip == "" }.empty?
          raise I18n.t('resource_import_textfile.error.series.head_is_blank')
        end
      end
    end

    def set_manifestation_type(field, datas, item)
      return if SystemConfiguration.get('manifestations.split_by_type')
      manifestation_type = item.manifestation.manifestation_type if item
      data_manifestation_type = datas[field[I18n.t('resource_import_textfile.excel.book.manifestation_type')]]
      if data_manifestation_type == '' or (manifestation_type.nil? and data_manifestation_type.nil?)
        raise I18n.t('resource_import_textfile.error.cell_require_manifestation_type')
      end
      if data_manifestation_type
        manifestation_type = ManifestationType.find_by_name(data_manifestation_type) rescue nil 
        unless manifestation_type
          raise I18n.t('resource_import_textfile.error.wrong_manifestation_type', :manifestation_type => data_manifestation_type) 
        end
      end
      return manifestation_type
    end

    def check_book_datas_has_necessary_field(field, datas, item, manifestation_type)
      # タイトル未入力で登録しようとしていないか確認
      if datas[field[I18n.t('resource_import_textfile.excel.book.original_title')]] == ''
        raise I18n.t('resource_import_textfile.error.book.not_delete')
      end
      return if item
      require_cell_book   = BOOK_REQUIRE_COLUMNS.map   { |c| datas[field[I18n.t("resource_import_textfile.excel.book.#{c}")]]   } 
      require_cell_series = SERIES_REQUIRE_COLUMNS.map { |c| datas[field[I18n.t("resource_import_textfile.excel.series.#{c}")]] }
      if manifestation_type.is_series?
        if require_cell_series.reject{ |f| f.to_s.strip == "" }.empty? or require_cell_book.reject{ |f| f.to_s.strip == "" }.empty?
          raise I18n.t('resource_import_textfile.error.series.cell_is_blank')
        end
      else
        if require_cell_book.reject{ |f| f.to_s.strip == "" }.empty?
          raise I18n.t('resource_import_textfile.error.book.cell_is_blank')
        end
      end
    end

    def check_duplicate_item_identifier(field, options = { oo: nil, datas: nil })
      col = field[I18n.t('resource_import_textfile.excel.book.item_identifier')]
      item_identifiers, duplicates = [], []
      set_id = lambda do |i_id|
        next if i_id.nil? or i_id.blank?
        duplicates << i_id if item_identifiers.include?(i_id)
        item_identifiers << i_id  
      end
      if options[:oo]
        # for excelx
        BOOK_DATA_ROW.upto(options[:oo].last_row) { |row| set_id.call(options[:oo].cell(row,col).try(:to_s).try(:strip)) }
      else
        # for tsv_csv
        options[:datas].each { |row| set_id.call(row[col]) }
      end
      unless duplicates.empty?
        raise I18n.t('resource_import_textfile.error.duplicate_item_identifier', :item_identifier => duplicates.join(',')) 
      end
    end

    def book_header_has_out_of_manage?(field)
      columns, unknown_columns = [], []
      columns << Manifestation::BOOK_COLUMNS.call.map { |c| I18n.t("resource_import_textfile.excel.book.#{c}") }
      columns << Manifestation::SERIES_COLUMNS.map    { |c| I18n.t("resource_import_textfile.excel.series.#{c}") }
      columns.flatten!
      unknown_columns = field.keys.map { |name| name unless columns.include?(name) }.compact
      unless unknown_columns.blank?
        logger.info " header has column that is out of manage"
        return I18n.t('resource_import_textfile.message.out_of_manage', :columns => unknown_columns.join(', '))
      end
      return ''
    end

    def import_book_data(import_textresult, field, datas, manifestation_type, textfile, numbering, auto_numbering, num, options = { sheet: sheet })
      item = nil
      item_identifier = datas[field[I18n.t('resource_import_textfile.excel.book.item_identifier')]]
      item = Item.where(:item_identifier => item_identifier.to_s).order("created_at asc").first unless item_identifier.nil? or item_identifier.blank?
      if fix_boolean(datas[field[I18n.t('resource_import_textfile.excel.book.del_flg')]], { mode: 'delete' })
        # delete mode
        delete_data(import_textresult, item_identifier, item)
      else
        # create / update mode
        manifestation_type = set_manifestation_type(field, datas, item) unless manifestation_type
        check_book_datas_has_necessary_field(field, datas, item, manifestation_type)

        manifestation, item, m_mode, import_textresult = fetch_book(field, datas, manifestation_type, item, import_textresult)
        item, i_mode, import_textresult = create_book_item(field, datas, textfile, numbering, auto_numbering, manifestation, item, import_textresult)
        import_textresult.manifestation = manifestation
        import_textresult.item = item
        manifestation.index
        manifestation.series_statement.index if manifestation.series_statement

        case m_mode
        when 'create' then num[:manifestation_imported] += 1
        when 'edit'   then num[:manifestation_found] += 1
        end
        case i_mode
        when 'create' then num[:item_imported] += 1
        when 'edit'   then num[:item_found] += 1
        end

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
    end

    def fetch_book(field, datas, manifestation_type, item = nil, import_textresult = nil)
      mode = 'create'
      manifestation = nil

      if item
        manifestation = item.manifestation
        mode = 'edit'
      end
      series_statement = find_series_statement(field, datas, manifestation, manifestation_type)
      manifestation, mode, item, error_msg = exist_same_book?(field, datas, manifestation_type, mode, manifestation, series_statement) unless manifestation
      isbn = datas[field[I18n.t('resource_import_textfile.excel.book.isbn')]].to_s
      manifestation = import_isbn(isbn) unless manifestation
      series_statement = create_series_statement(field, datas, mode, manifestation_type, manifestation, series_statement)

      manifestation = Manifestation.new unless manifestation
      manifestation.series_statement = series_statement if series_statement
      original_title         = datas[field[I18n.t('resource_import_textfile.excel.book.original_title')]]
      title_transcription    = datas[field[I18n.t('resource_import_textfile.excel.book.title_transcription')]]
      title_alternative      = datas[field[I18n.t('resource_import_textfile.excel.book.title_alternative')]]
      carrier_type           = set_data(field, datas, mode, CarrierType, 'carrier_type', { :default => 'print' })
      jpn_or_foreign         = check_jpn_or_foreign(datas[field[I18n.t('resource_import_textfile.excel.book.jpn_or_foreign')]])
      frequency              = set_data(field, datas, mode, Frequency, 'frequency', { :default => '不明', :check_column => :display_name })
      country_of_publication = set_data(field, datas, mode, Country, 'country_of_publication', { :default => 'unknown' }) 
      pub_date               = datas[field[I18n.t('resource_import_textfile.excel.book.pub_date')]]
      place_of_publication   = datas[field[I18n.t('resource_import_textfile.excel.book.place_of_publication')]]
      language               = set_data(field, datas, mode,  Language, 'language', { :default => 'Japanese' })
      edition                = datas[field[I18n.t('resource_import_textfile.excel.book.edition_display_value')]]
      volume_number_string   = datas[field[I18n.t('resource_import_textfile.excel.book.volume_number_string')]]
      issue_number_string    = datas[field[I18n.t('resource_import_textfile.excel.book.issue_number_string')]]
      serial_number_string   = datas[field[I18n.t('resource_import_textfile.excel.book.serial_number_string')]]
      issn                   = datas[field[I18n.t('resource_import_textfile.excel.series.issn')]]
      lccn                   = datas[field[I18n.t('resource_import_textfile.excel.book.lccn')]]
      marc_number            = datas[field[I18n.t('resource_import_textfile.excel.book.marc_number')]]
      ndc                    = datas[field[I18n.t('resource_import_textfile.excel.book.ndc')]]
      start_page             = datas[field[I18n.t('resource_import_textfile.excel.book.start_page')]]
      end_page               = datas[field[I18n.t('resource_import_textfile.excel.book.end_page')]]
      height                 = check_data_is_numeric(datas[field[I18n.t('resource_import_textfile.excel.book.height')]], 'height')
      width                  = check_data_is_numeric(datas[field[I18n.t('resource_import_textfile.excel.book.width')]], 'width') 
      depth                  = check_data_is_numeric(datas[field[I18n.t('resource_import_textfile.excel.book.depth')]], 'depth')
      price                  = check_data_is_integer(datas[field[I18n.t('resource_import_textfile.excel.book.price')]], 'price')
      access_address         = datas[field[I18n.t('resource_import_textfile.excel.book.access_address')]]
      acceptance_number      = check_data_is_integer(datas[field[I18n.t('resource_import_textfile.excel.book.acceptance_number')]], 'acceptance_number')
      repository_content     = fix_boolean(datas[field[I18n.t('resource_import_textfile.excel.book.repository_content')]], { mode: mode })
      required_role          = set_data(field, datas, mode, Role, 'required_role', { :default => 'Guest' })
      except_recent          = fix_boolean(datas[field[I18n.t('resource_import_textfile.excel.book.except_recent')]], { mode: mode })
      description            = datas[field[I18n.t('resource_import_textfile.excel.book.description')]]
      supplement             = datas[field[I18n.t('resource_import_textfile.excel.book.supplement')]]
      note                   = datas[field[I18n.t('resource_import_textfile.excel.book.note')]]
      missing_issue          = set_missing_issue(datas[field[I18n.t('resource_import_textfile.excel.book.missing_issue')]])
      manifestation.manifestation_type        = manifestation_type
      manifestation.periodical                = true                      if manifestation.series_statement and manifestation.series_statement.periodical
      manifestation.original_title            = original_title.to_s       unless original_title.nil?
      manifestation.title_transcription       = title_transcription.to_s  unless title_transcription.nil?
      manifestation.title_alternative         = title_alternative.to_s    unless title_alternative.nil?
      manifestation.carrier_type              = carrier_type              unless carrier_type.nil?
      manifestation.frequency                 = frequency                 unless frequency.nil?
      manifestation.pub_date                  = pub_date.to_s             unless pub_date.nil?
      manifestation.country_of_publication_id = country_of_publication.id unless country_of_publication.nil? 
      manifestation.place_of_publication      = place_of_publication.to_s unless place_of_publication.nil?
      manifestation.language                  = language                  unless language.nil?
      manifestation.edition_display_value     = edition                   unless edition.nil?
      manifestation.volume_number_string      = volume_number_string.to_s unless volume_number_string.nil?
      manifestation.issue_number_string       = issue_number_string.to_s  unless issue_number_string.nil?
      manifestation.serial_number_string      = serial_number_string.to_s unless serial_number_string.nil?
      manifestation.isbn                      = isbn.to_s                 unless isbn.nil?
      manifestation.issn                      = issn.to_s                 unless issn.nil?
      manifestation.lccn                      = lccn.to_s                 unless lccn.nil?
      manifestation.marc_number               = marc_number.to_s          unless marc_number.nil?
      manifestation.ndc                       = ndc.to_s                  unless ndc.nil?
      manifestation.height                    = height                    unless height.nil?
      manifestation.width                     = width                     unless width.nil?
      manifestation.depth                     = depth                     unless depth.nil?
      manifestation.price                     = price                     unless price.nil?
      manifestation.access_address            = access_address.to_s       unless access_address.nil?
      manifestation.acceptance_number         = acceptance_number         unless acceptance_number.nil?
      manifestation.repository_content        = repository_content        unless repository_content.nil?
      manifestation.required_role             = required_role             unless required_role.nil?
      manifestation.except_recent             = except_recent             unless except_recent.nil?
      manifestation.description               = description.to_s          unless description.nil?
      manifestation.supplement                = supplement.to_s           unless supplement.nil?
      manifestation.note                      = note.to_s                 unless note.nil?
      manifestation.during_import             = true
      unless jpn_or_foreign.nil?
        manifestation.jpn_or_foreign = jpn_or_foreign.blank? ? nil : jpn_or_foreign
      end
      unless start_page.nil?
        if start_page.to_s.blank?
          manifestation.start_page = nil
        else
          manifestation.start_page = start_page.to_s
        end
      end
      unless end_page.nil?
        if end_page.to_s.blank?
          manifestation.end_page = nil
        else
          manifestation.end_page = end_page.to_s
        end
      end
      unless missing_issue.nil?
        if missing_issue.blank?
          manifestation.missing_issue = nil
        else
          manifestation.missing_issue = missing_issue.to_i
        end
      end
      manifestation.save!
      if mode == "create"
        p "make new manifestation"
      else
        p "edit manifestation title:#{manifestation.original_title}"
      end
      # creator
      creators_string = datas[field[I18n.t('resource_import_textfile.excel.book.creator')]]
      creators        = creators_string.nil? ? nil : creators_string.to_s.gsub('；', ';').split(';')
      unless creators.nil?
        creators_list   = creators.inject([]){ |list, creator| list << {:full_name => creator.to_s.strip, :full_name_transcription => "" } }
        creator_patrons = Patron.import_patrons(creators_list)
        manifestation.creators = creator_patrons
      end
      # publisher
      publishers_string = datas[field[I18n.t('resource_import_textfile.excel.book.publisher')]]
      publishers        = publishers_string.nil? ? nil : publishers_string.to_s.gsub('；', ';').split(';')
      unless publishers.nil?
        publishers_list   = publishers.inject([]){ |list, publisher| list << {:full_name => publisher.to_s.strip, :full_name_transcription => "" } }
        publisher_patrons = Patron.import_patrons(publishers_list)
        manifestation.publishers = publisher_patrons
      end
      # contributor
      contributors_string = datas[field[I18n.t('resource_import_textfile.excel.book.contributor')]]
      contributors        = contributors_string.nil? ? nil : contributors_string.to_s.gsub('；', ';').split(';')
      unless contributors.nil?
        contributors_list   = contributors.inject([]){ |list, contributor| list << {:full_name => contributor.to_s.strip, :full_name_transcription => "" } }
        contributor_patrons = Patron.import_patrons(contributors_list)
        #TODO update contributor position withou destroy_all
        manifestation.contributors.destroy_all unless manifestation.contributors.empty?
        manifestation.contributors = contributor_patrons
      end
      # subject
      subjects_list = datas[field[I18n.t('resource_import_textfile.excel.article.subject')]]
      unless subjects_list.nil?
        subjects = Subject.import_subjects(subjects_list)
        manifestation.subjects = subjects
      end
      import_textresult.error_msg = error_msg if error_msg
      return manifestation, item, mode, import_textresult
    end

    def exist_same_book?(field, datas, manifestation_type, mode, manifestation, series_statement = nil)
      error_msg = ""
      original_title    = datas[field[I18n.t('resource_import_textfile.excel.book.original_title')]]
      pub_date          = datas[field[I18n.t('resource_import_textfile.excel.book.pub_date')]]
      creators_string   = datas[field[I18n.t('resource_import_textfile.excel.book.creator')]]
      creators          = creators_string.nil? ? nil : creators_string.to_s.gsub('；', ';').split(';')
      publishers_string = datas[field[I18n.t('resource_import_textfile.excel.book.publisher')]]
      publishers        = publishers_string.nil? ? nil : publishers_string.to_s.gsub('；', ';').split(';')
      series_title      = datas[field[I18n.t('resource_import_textfile.excel.series.original_title')]]

      if manifestation
        original_title = manifestation.original_title.to_s                if original_title.nil?
        pub_date       = manifestation.pub_date.to_s                      if pub_date.nil?
        creators       = manifestation.creators.map{ |c| c.full_name }    if creators.nil?
        publishers     = manifestation.publishers.map{ |p| p.full_name }  if publishers.nil?
      end
      if series_statement
        series_title   = series_statement.original_title.to_s             if series_title.nil?
      end
      return manifestation, mode if original_title.nil? or original_title.blank?
      return manifestation, mode if pub_date.nil? or pub_date.blank?
      return manifestation, mode if creators.nil? or creators.size == 0
      return manifestation, mode if publishers.nil? or publishers.size == 0
      conditions = []
      conditions << "(manifestations).original_title = \'#{original_title.to_s.gsub("'","''")}\'" 
      conditions << "(manifestations).pub_date = \'#{pub_date.to_s.gsub("'", "''")}\'"
      conditions << "(series_statements).original_title = \'#{series_title.to_s.gsub("'", "''")}\'" if manifestation_type.is_series?
      conditions << "creates.id is not null"
      conditions << "produces.id is not null"
      conditions << "manifestations.id != #{manifestation.id}" if manifestation.try(:id)
      conditions = conditions.join(' and ')

      books = Manifestation.find(
        :all,
        :readonly => false,
        :include => [:series_statement, :creators, :publishers],
        :conditions => conditions,
        :order => "manifestations.created_at asc"
      )
      if books
        same_books = []
        books.each do |book|
          b_creators = book.creators.pluck(:full_name).sort rescue nil
          b_publishers = book.publishers.pluck(:full_name).sort rescue nil
          same_books << book if b_creators == creators and b_publishers == publishers
        end
        if same_books.size > 1
          # 書誌同定で対象となる本が複数存在する場合は新規作成とする
          error_msg = I18n.t('resource_import_textfile.error.book.exist_multiple_same_manifestations')
        elsif same_books.size == 1
          p "editing manifestation"
          mode = 'edit'
          if same_books.first.items.size == 1
            return same_books.first, mode, same_books.first.items.first
          end
        end
      end
      p "make new manifestation"
      return manifestation, mode, nil, error_msg
    end

    def import_isbn(isbn)
      manifestation = nil
      unless isbn.blank?
        begin
          isbn = Lisbn.new(isbn)
          exist_manifestation = Manifestation.find_by_isbn(isbn)
          unless exist_manifestation
            manifestation = Manifestation.import_isbn(isbn)
            # raise I18n.t('resource_import_textfile.error.book.wrong_isbn') unless manifestation
          else
            manifestation = exist_manifestation
          end
        rescue EnjuNdl::InvalidIsbn
          raise I18n.t('resource_import_textfile.error.book.wrong_isbn')
        rescue EnjuNdl::RecordNotFound
          raise I18n.t('resource_import_textfile.error.book.record_not_found')
        end
      end
      manifestation.external_catalog = 1 if manifestation
      return manifestation
    end

    def find_series_statement(field, datas, manifestation, manifestation_type)
      return nil unless manifestation_type.is_series?
      series_statement = nil
      series_statement = manifestation.series_statement if manifestation and manifestation.series_statement
      unless series_statement
        issn = datas[field[I18n.t('resource_import_textfile.excel.series.issn')]]
        if issn
          begin
            issn = Lisbn.new(issn.to_s)
          rescue
            raise I18n.t('resource_import_textfile.error.series.wrong_issn')
          end
          series_statement = SeriesStatement.where(:issn => issn).first unless series_statement
        end
      end
      return series_statement
    end

    def create_series_statement(field, datas, mode, manifestation_type, manifestation, series_statement)
      return nil unless manifestation_type.is_series?

      original_title      = datas[field[I18n.t('resource_import_textfile.excel.series.original_title')]]
      title_transcription = datas[field[I18n.t('resource_import_textfile.excel.series.title_transcription')]]
      periodical          = fix_boolean(datas[field[I18n.t('resource_import_textfile.excel.series.periodical')]], { mode: mode })
      series_identifier   = datas[field[I18n.t('resource_import_textfile.excel.series.series_statement_identifier')]]
      issn                = datas[field[I18n.t('resource_import_textfile.excel.series.issn')]]
      note                = datas[field[I18n.t('resource_import_textfile.excel.series.note')]]
      unless series_statement
        conditions = []
        conditions << "original_title = \'#{original_title.to_s.gsub("'","''")}\'" unless original_title.nil? or original_title.blank?
        conditions << "title_transcription = \'#{title_transcription.to_s.gsub("'","''")}\'" unless title_transcription.nil? or title_transcription.blank?
        conditions << "periodical = #{periodical}" unless periodical.nil? or periodical.blank?
        conditions << "series_identifier = \'#{series_identifier.to_s.gsub("'","''")}\'" unless series_identifier.nil? or series_identifier.blank?
        conditions << "issn = \'#{issn.to_s.gsub("'","''")}\'" unless issn.nil? or issn.blank?
        conditions << "note = \'#{note.to_s.gsub("'","''")}\'" unless note.nil? or note.blank?
        exist_series = SeriesStatement.find(
          :first,
          :readonly => false,
          :conditions => conditions,
          :order => "created_at asc"
        )
        unless exist_series.nil?
          if manifestation and manifestation.series_statement
            if manifestation.series_statement == exist_series
              series_statement = manifestation.series_statement
            else
              raise I18n.t('resource_import_textfile.error.series.exist_same_series')
            end
          else
            series_statement = exist_series
          end
        end
      end

      unless series_statement
        p "make new series_statement"
        series_statement = SeriesStatement.new
      else
        p "edit series_statement name:#{original_title}"
      end

      series_statement.original_title              = original_title.to_s      unless original_title.nil?
      series_statement.title_transcription         = title_transcription.to_s unless title_transcription.nil?
      series_statement.periodical                  = periodical               unless periodical.nil?
      series_statement.series_statement_identifier = series_identifier.to_s   unless series_identifier.nil?
      series_statement.issn                        = issn.to_s                unless issn.nil?
      series_statement.note                        = note.to_s                unless note.nil?
      if series_statement.periodical == true and series_statement.root_manifestation.nil?
        root_manifestation = Manifestation.new(:original_title => series_statement.original_title)
        root_manifestation.periodical_master = true
        series_statement.root_manifestation = root_manifestation
      end
      series_statement.save! 
      series_statement.manifestations << root_manifestation if root_manifestation
      series_statement.index
      return series_statement
    end

    def create_book_item(field, datas, textfile, numbering, auto_numbering, manifestation, item, import_textresult)
      resource_import_textfile = ResourceImportTextfile.find(textfile.id)
      mode = 'edit'
      unless item
        unless field[I18n.t('resource_import_textfile.excel.book.item_identifier')] || auto_numbering
          import_textresult.error_msg = I18n.t('resource_import_textfile.message.without_item')
          return item, mode, import_textresult
        end
        item = Item.new
        mode = 'create'
      end

      accept_type         = set_data(field, datas, mode, AcceptType, 'accept_type', { :can_blank => true, :check_column => :display_name })
      acquired_at         = datas[field[I18n.t('resource_import_textfile.excel.book.acquired_at')]]
      library             = set_library(datas[field[I18n.t('resource_import_textfile.excel.book.library')]], resource_import_textfile.user)
      shelf               = set_shelf(datas[field[I18n.t('resource_import_textfile.excel.book.shelf')]], resource_import_textfile.user, library)
      checkout_type       = set_data(field, datas, mode, CheckoutType, 'checkout_type', { :default => 'book' })
      circulation_status  = set_data(field, datas, mode, CirculationStatus, 'circulation_status', { :default => 'In Process' })
      retention_period    = set_data(field, datas, mode, RetentionPeriod, 'retention_period', { :default => '永年', :check_column => :display_name })
      call_number         = datas[field[I18n.t('resource_import_textfile.excel.book.call_number')]]
      price               = check_data_is_integer(datas[field[I18n.t('resource_import_textfile.excel.book.item_price')]], 'item_price')
      url                 = datas[field[I18n.t('resource_import_textfile.excel.book.url')]]
      include_supplements = fix_boolean(datas[field[I18n.t('resource_import_textfile.excel.book.include_supplements')]], { mode: mode })
      use_restriction     = fix_use_restriction(datas[field[I18n.t('resource_import_textfile.excel.book.use_restriction')]])
      note                = datas[field[I18n.t('resource_import_textfile.excel.book.item_note')]]
      required_role       = set_data(field, datas, mode, Role, 'required_role', { :default => 'Guest' })
      remove_reason       = set_data(field, datas, mode, RemoveReason, 'remove_reason', { :can_blank => true, :check_column => :display_name })
      item_identifier     = datas[field[I18n.t('resource_import_textfile.excel.book.item_identifier')]]
      non_searchable      = fix_boolean(datas[field[I18n.t('resource_import_textfile.excel.book.non_searchable')]], { mode: mode })

      # rank
      rank = fix_rank(datas[field[I18n.t('resource_import_textfile.excel.book.rank')]], { manifestation: manifestation, mode: mode })
      if item.item_identifier.nil? and item_identifier.nil?
        if item_identifier.nil? && auto_numbering
          begin
            create_item_identifier = Numbering.do_numbering(numbering.name)
          end while Item.where(:item_identifier => create_item_identifier).first
          item_identifier = create_item_identifier
        end
        raise I18n.t("resource_import_textfile.error.no_item_identifier") if item_identifier.nil?
      end
      unless rank.nil?
        item.rank = rank
      else
        item.rank = '' if datas[field[I18n.t('resource_import_textfile.excel.book.rank')]] == ''
      end
      # accept_type
      unless accept_type.nil?
        item.accept_type = accept_type
      else
        item.accept_type = nil if datas[field[I18n.t('resource_import_textfile.excel.book.accept_type')]] == ''
      end
      # use_restriction
      unless use_restriction.nil?
        item.use_restriction_id = use_restriction.id
      else
        item.use_restriction_id = item.use_restriction.id if item.use_restriction
      end
      item.manifestation_id    = manifestation.id
      item.library_id          = library.id           unless library.nil?
      item.shelf               = shelf                unless shelf.nil?
      item.checkout_type       = checkout_type        unless checkout_type.nil?
      item.circulation_status  = circulation_status   unless circulation_status.nil?
      item.retention_period    = retention_period     unless retention_period.nil?
      item.call_number         = call_number.to_s     unless call_number.nil?
      item.price               = price                unless price.nil?
      item.url                 = url.to_s             unless url.nil?
      item.include_supplements = include_supplements  unless include_supplements.nil?
      item.note                = note.to_s            unless note.nil?
      item.required_role       = required_role        unless required_role.nil?
      item.item_identifier     = item_identifier.to_s unless item_identifier.nil?
      item.non_searchable      = non_searchable       unless non_searchable.nil?
      item.acquired_at_string  = acquired_at.to_s     unless acquired_at.nil?

      # bookstore
      bookstore_name = datas[field[I18n.t('resource_import_textfile.excel.book.bookstore')]]
      if bookstore_name == ""
        item.bookstore = nil
      else
        bookstore = Bookstore.import_bookstore(bookstore_name) rescue nil
        unless bookstore.nil?
          item.bookstore = bookstore == "" ? nil : bookstore
        end
      end
      # if removed?
      item.remove_reason = remove_reason unless remove_reason.nil?
      unless remove_reason.nil?
        item.remove_reason = remove_reason
        if datas[field[I18n.t('resource_import_textfile.excel.book.circulation_status')]].nil?
          item.circulation_status = CirculationStatus.where(:name => "Removed").first
        end
        item.removed_at = Time.zone.now
      else
        if datas[field[I18n.t('resource_import_textfile.excel.book.remove_reason')]] == ''
          item.circulation_status = CirculationStatus.where(:name => "In Process").first if circulation_status.nil?
          item.remove_reason = nil
        end
      end

      if mode == 'create'
        p "make new item"
      else
        p "editing item: #{item.item_identifier}"
      end
      item.save!
      item.patrons << shelf.library.patron if mode == 'create'
      item.manifestation = manifestation
      unless item.remove_reason.nil?
        if item.reserve
          item.reserve.revert_request rescue nil
        end
      end
      return item, mode, import_textresult
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
        #if manifestation.items.map{ |i| i.rank.to_i }.compact.include?(0)
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
            if options[:manifestation].items.map{ |i| i.rank.to_i }.compact.include?(0)
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

    def set_data(field, datas, mode, model, field_name, options)
      obj = nil
      options[:can_blank]    = false    if options[:can_blank].nil?
      options[:check_column] = :name    if options[:check_column].nil?

      cell = datas[field[I18n.t("resource_import_textfile.excel.book.#{field_name}")]]
      if cell.nil?
        if options[:can_blank]
          obj = nil
        elsif mode != 'create'
          obj = nil
        else
          obj = model.where(options[:check_column] => options[:default]).first 
        end
      elsif options[:can_blank] == true and cell.blank?
        obj = nil
      else
        #obj = options[:model].where(options[:check_column] => cell).first# rescue nil
        obj = model.where(options[:check_column] => cell).first# rescue nil
        if obj.nil?
          raise I18n.t('resource_import_textfile.error.wrong_data',
             :field => I18n.t("resource_import_textfile.excel.book.#{field_name}"), :data => cell)
        end
      end
      return obj
    end

    def check_data_is_integer(cell, field_name, options = {:mode => 'create'})
      if options[:mode] == "delete"
        return nil if cell.nil? or cell.blank?
      end
      return nil unless cell
      cell = cell.to_s.strip
      if cell.match(/^\d*$/)
        return cell
      elsif cell.match(/^[0-9]+\.0$/)
        return cell.to_i
      elsif cell.match(/\D/)
        raise I18n.t('resource_import_textfile.error.book.only_integer',
          :field => I18n.t("resource_import_textfile.excel.book.#{field_name}"), :data => cell)
      end
    end

    def check_data_is_numeric(cell, field_name, options = {:mode => 'create'})
      if options[:mode] == "delete" 
        return nil if cell.nil? or cell.blank?
      end
      return nil unless cell
      cell = cell.to_s.strip
      if cell.match(/^\d*$/)
        return cell
      elsif cell.match(/^[0-9]+\.0$/)
        return cell.to_i
      elsif cell.match(/^[0-9]*\.[0-9]*$/)
        return cell
      else
        raise I18n.t('resource_import_textfile.error.book.only_numeric',
          :field => I18n.t("resource_import_textfile.excel.book.#{field_name}"), :data => cell)
      end
    end

    def check_data_is_date(cell, field_name, options = {:mode => 'create'})
      if options[:mode] == "delete"
        return nil if cell.nil? or cell.blank?
      end
      return nil unless cell
      cell = cell.to_s.strip
      unless cell.blank?
        time = Time.zone.parse(cell) rescue nil
        if time.nil?
          raise I18n.t('resource_import_textfile.error.book.only_date',
            :field => I18n.t("resource_import_textfile.excel.book.#{field_name}"), :data => cell)
        end
      end
      return time
    end

    def check_jpn_or_foreign(jpn_or_foreign)
      return nil unless jpn_or_foreign
      unless jpn_or_foreign.blank?
        if jpn_or_foreign.to_s != '0' and jpn_or_foreign.to_s != '1'
          raise I18n.t('resource_import_textfile.error.book.wrong_jpn_or_foreign', :data => jpn_or_foreign)
        end
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

    def set_missing_issue(missing_issue, options = {:mode => 'create'})
      return nil if missing_issue.nil?
      missing_issue = missing_issue.to_s.strip
      if missing_issue == I18n.t('missing_issue.no_request')
        return 1
      elsif missing_issue == I18n.t('missing_issue.requested')
        return 2
      elsif missing_issue == I18n.t('missing_issue.received')
        return 3
      elsif missing_issue.blank?
        return options[:mode] == 'delete' ? nil : ""
      else
        raise I18n.t('resource_import_textfile.error.book.wrong_missing_issue', :data => missing_issue)
      end
    end

    def delete_data(import_textresult, item_identifier, item) 
      raise I18n.t('resource_import_textfile.error.delete_requre_item_identifier') if item_identifier.nil? or item_identifier.blank?
      raise I18n.t('resource_import_textfile.error.failed_delete_not_find') unless item

      deleted_manifestation          = false
      deleted_series_statement       = false
      deleted_manifestation_title    = nil
      deleted_series_title = nil

      manifestation = item.manifestation
      series_statement = manifestation.series_statement
      item.destroy
      p "deleted item_identifier: #{item_identifier}"
      if manifestation.items.blank? or manifestation.items.size == 0
        deleted_manifestation_title = manifestation.original_title
        manifestation.destroy
        p "deleted manifestation_title: #{deleted_manifestation_title}"
        deleted_manifestation = true
      end
      if series_statement
        if series_statement.periodical and series_statement.manifestations.size == 1
          series_manifestation = series_statement.manifestations.first
          series_manifestation.destroy if series_manifestation.periodical_master
        end
        if series_statement.manifestations.blank? or series_statement.manifestations.size == 0
          deleted_series_title = series_statement.original_title
          series_statement.destroy
          p "deleted series_statement_title: #{deleted_series_title}"
          deleted_series_statement = true
        end
      end
      import_textresult.error_msg = "#{I18n.t('resource_import_textfile.message.deleted', :item_identifier => item_identifier)} "
      import_textresult.error_msg += " / #{I18n.t('resource_import_textfile.message.deleted_manifestation', :original_title => deleted_manifestation_title)} " if  deleted_manifestation
      import_textresult.error_msg += " / #{I18n.t('resource_import_textfile.message.deleted_series_statement', :series_original_title => deleted_series_title)} " if deleted_series_statement
    end
  end
end

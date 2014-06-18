# -*- encoding: utf-8 -*-
module EnjuTrunk
  module ImportArticle
    ARTICLE_REQUIRE_COLUMNS  = %w(original_title).map {|c| "article.#{c}" }
    ARTICLE_HEADER_ROW       = 1
    ARTICLE_DATA_ROW         = 2

    def article_default_datas
      return @article_default_datas if @article_default_datas

      @article_default_datas = {
        # default setting: manifestation
        carrier_type: CarrierType.where(:name => 'print').first,
        frequency:    Frequency.where(:name => 'unknown').first,
        role:         Role.find('Guest'),
        # default setting: item
        circulation_status: CirculationStatus.where(:name => 'Not Available').first,
        use_restriction:    UseRestriction.where(:name => 'Not For Loan').first,
        checkout_type:      CheckoutType.where(:name => 'article').first,
        rank:               0,
      }
    end

    def check_article_header_has_necessary_field(sheet)
      unless sheet.include_all?(ARTICLE_REQUIRE_COLUMNS)
        raise I18n.t('resource_import_textfile.error.article.head_is_blank')
      end
    end

    def check_article_datas_has_necessary_field(origin_datas, sheet)
      unless sheet.filled_all?(origin_datas, ARTICLE_REQUIRE_COLUMNS)
        raise I18n.t('resource_import_textfile.error.article.cell_is_blank')
      end
    end

    def article_header_has_out_of_manage(sheet)
      field_names = Manifestation.article_output_columns.
        map {|key| sheet.field_name(key) }
      unknown = sheet.field.keys.
        reject {|name| field_names.include?(name) }
      unless unknown.blank?
        logger.info " header has column that is out of manage"
        return I18n.t('resource_import_textfile.message.out_of_manage', :columns => unknown_columns.join(', '))
      end
      return ''
    end

    def article_attributes(origin_datas, sheet)
      attrs = {}
      Manifestation.article_output_columns.each do |column|
        name, value = sheet.field_name_and_data(origin_datas, column)

        case name
        when sheet.field_name('article.original_title')
          attrs.store('original_title', value)
        when sheet.field_name('article.title')
          attrs.store('article_title', value)
        when sheet.field_name('article.pub_date')
          attrs.store('pub_date', value)
        when sheet.field_name('article.access_address')
          attrs.store('access_address', value)
        when sheet.field_name('article.number_of_page')
          start_page, end_page = nil, nil
          unless value.nil?
            page = value.to_s
            if page.present?
              if page.match(/\-/)
                start_page = fix_data(page.split('-')[0]) rescue ''
                end_page   = fix_data(page.split('-')[1]) rescue ''
              else
                start_page, end_page = page, ''
              end
            else
              start_page, end_page = '', ''
            end
          end
          attrs.store('start_page', start_page)
          attrs.store('end_page', end_page)
        when sheet.field_name('article.volume_number_string')
          volume_number_string, issue_number_string = nil, nil
          unless value.nil?
            value = value.to_s
            if value.present?
              if value.match(/\*/)
                volume_number_string = value.split('*')[0] rescue ''
                issue_number_string  = value.split('*')[1] rescue ''
              else
                volume_number_string, issue_number_string =  '', value
              end
            else
              volume_number_string, issue_number_string = '', ''
            end
          end
          attrs.store('volume_number_string', volume_number_string)
          attrs.store('issue_number_string', issue_number_string)
        when sheet.field_name('article.creator')
          attrs.store('creators', sheet.manifestation_type.name == 'japanese_article' ? value : value.to_s.gsub(' ', ';'))
        when sheet.field_name('article.subject')
          attrs.store('subjects', sheet.manifestation_type.name == 'japanese_article' ? value : value.to_s.gsub(/\*|＊/, ';'))
        when sheet.field_name('article.call_number')
          attrs.store('call_number', value)
        end
      end
      p "---- attrs --------------------"
      attrs.each {|key, value| p "#{key}: #{value}" }

      attrs
    end

    def process_article_data(import_textresult, origin_datas, sheet, textfile, numbering)
      check_article_datas_has_necessary_field(origin_datas, sheet)

      attrs = article_attributes(origin_datas, sheet)
      item, mode, error_msg = find_same_item(attrs, sheet.manifestation_type)
      import_textresult.error_msg = error_msg if error_msg

      manifestation, m_mode = create_article_manifestation(attrs, item, sheet.manifestation_type, mode)
      item, i_mode          = create_article_item(attrs, manifestation, item, textfile, numbering, mode)

      item.manifestation = manifestation
      import_textresult.manifestation = manifestation
      import_textresult.item          = item

      case m_mode
      when 'create' then update_summary(:manifestation_imported)
      when 'edit'   then update_summary(:manifestation_found)
      end
      case i_mode
      when 'create' then update_summary(:item_imported)
      when 'edit'   then update_summary(:item_found)
      end

      manifestation.index
      if import_textresult.item.manifestation.next_reserve and import_textresult.item.item_identifier
        current_user = User.where(:username => 'admin').first
        import_textresult.item.retain(current_user) if import_textresult.item.available_for_retain?
        import_textresult.error_msg = I18n.t(
          'resource_import_file.reserved_item',
          :username => import_textresult.item.reserve.user.username,
          :user_number => import_textresult.item.reserve.user.user_number
        )
      end
    end

    def create_article_manifestation(attrs, item, manifestation_type, mode = 'edit')
      manifestation = nil
      if item
         manifestation = item.manifestation
      else
        mode = 'create'
        manifestation = Manifestation.new(
          :carrier_type   => article_default_datas[:carrier_type],
          :frequency      => article_default_datas[:frequency],
          :required_role  => article_default_datas[:role],
          :except_recent  => article_default_datas[:except_recent],
          :during_import  => true,
        )
      end
      p mode == 'create' ? "create new manifestation" : "edit manifestation / id:#{manifestation.id}"

      manifestation.manifestation_type = manifestation_type
      attrs.each do |key, value|
        unless ['call_number', 'creators', 'subjects'].include?(key)
          manifestation[key] = value.to_s unless value.nil?
        end
      end
      manifestation.save!
      manifestation.creators = Agent.add_agents(attrs['creators'].to_s) unless attrs['creators'].nil?
      manifestation.subjects = Subject.import_subjects(attrs['subjects'].to_s) unless attrs['subjects'].nil?
      manifestation.languages = Language.where(:name => 'unknown')
      return manifestation, mode
    end

    def create_article_item(attrs, manifestation, item, textfile, numbering, mode = 'edit')
      unless item
        if manifestation.items.size < 1
          mode = 'create'
          item = Item.new
        else
          item = manifestation.items.order('created_at asc').first
        end
      end
      p mode == 'create' ? "create new item" : "edit item / id: #{item.id} / item_identifer: #{item.item_identifier}"

      item.circulation_status = article_default_datas[:circulation_status]
      item.use_restriction    = article_default_datas[:use_restriction]
      item.checkout_type      = article_default_datas[:checkout_type]
      item.rank               = article_default_datas[:rank]
      item.shelf_id           = textfile.user.library.article_shelf.id
      item.call_number        = attrs['call_number'].to_s unless attrs['call_number'].nil?
      while item.item_identifier.nil?
        item_identifier = Numbering.do_numbering(numbering.name)
        item.item_identifier = item_identifier unless Item.where(:item_identifier => item_identifier).first
      end
      item.save!
      item.agents << textfile.user.library.agent if mode == 'create'
      return item, mode
    end

    def find_same_item(attrs, manifestation_type)
      conditions = ["((manifestations).manifestation_type_id = \'#{manifestation_type.id}\')"] # FIXME!
      attrs.each do |key, value|
        case key
        when 'creators', 'subjects'
          conditions << "#{key == 'creators' ? 'creates' : 'subjects'}.id IS #{'NOT' unless value.nil? or value.blank?} NULL"
        else
          model = 'manifestations'
          model = 'items' if key == 'call_number'
          if value.nil? or value.blank?
            conditions << "((#{model}).#{key} IS NULL OR (#{model}).#{key} = '')" # FIXME!!
          else
            conditions << "((#{model}).#{key} = \'#{value.to_s.gsub("'", "''")}\')" # FIXME!!
          end
        end
      end
      conditions = conditions.join(' AND ')
      p "---- conditions --------------------"
      p conditions

      creators = split_by_semicolon(attrs['creators']).sort rescue []
      subjects = split_by_semicolon(attrs['subjects']).sort rescue []
      same_item = []

      Item.find(
        :all,
        :include => [:manifestation => [:creators, :subjects]],
        :conditions => conditions,
        :order => "items.created_at asc"
      ).each do |item|
        a_creators = item.manifestation.creators.pluck(:full_name).sort rescue []
        a_subjects = item.manifestation.subjects.pluck(:term).sort rescue []
        same_item << item if a_creators == creators and a_subjects == subjects
      end

      if same_item.size > 1
        # 書誌同定で対象となる本が複数存在する場合は新規作成とする
        error_msg = I18n.t('resource_import_textfile.error.book.exist_multiple_same_manifestations')
        return nil, nil, error_msg
      elsif same_item.size == 1
        return same_item.first, 'edit', nil
      end
      return nil, nil, nil
    end
  end
end

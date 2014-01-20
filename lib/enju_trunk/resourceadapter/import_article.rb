# -*- encoding: utf-8 -*-
module EnjuTrunk
  module ImportArticle
    ARTICLE_COLUMNS = %w(
      creator original_title title volume_number_string number_of_page pub_date call_number access_address subject
    )
    ARTICLE_REQUIRE_COLUMNS  = %w(original_title)
    ARTICLE_HEADER_ROW       = 1
    ARTICLE_DATA_ROW         = 2

    def set_article_default_datas
      default_datas = Hash::new
      # default setting: manifestation
      default_datas.store(:language,     Language.where(:name => 'unknown').first)
      default_datas.store(:carrier_type, CarrierType.where(:name => 'print').first)
      default_datas.store(:frequency,    Frequency.where(:name => 'unknown').first)
      default_datas.store(:role,         Role.find('Guest'))
      # default setting: item
      default_datas.store(:circulation_status, CirculationStatus.where(:name => 'Not Available').first)
      default_datas.store(:use_restriction,    UseRestriction.where(:name => 'Not For Loan').first)
      default_datas.store(:checkout_type,      CheckoutType.where(:name => 'article').first)
      default_datas.store(:rank,               0) 
    end

    def check_article_header_has_necessary_field(field)
      require_fields = ARTICLE_REQUIRE_COLUMNS.map { |c| I18n.t("resource_import_textfile.excel.article.#{c}") }
      unless (require_fields & field.keys) == require_fields
        raise I18n.t('resource_import_textfile.error.article.head_is_blank')
      end
    end

    def check_article_datas_has_necessary_field(field, origin_datas)
      require_field_nums = ARTICLE_REQUIRE_COLUMNS.map { |c| field[I18n.t("resource_import_textfile.excel.article.#{c}")] }
      unless (require_field_nums & origin_datas.map{ |key, value| key if value and value != ''}.compact) == require_field_nums
        raise I18n.t('resource_import_textfile.error.article.cell_is_blank') 
      end
    end

    def article_header_has_out_of_manage?(field)
      columns = Manifestation::ARTICLE_COLUMNS.map { |c| I18n.t("resource_import_textfile.excel.article.#{c}") }
      unknown_columns = field.keys.map { |name| name unless columns.include?(name) }.compact
      unless unknown_columns.blank?
        logger.info " header has column that is out of manage"
        return I18n.t('resource_import_textfile.message.out_of_manage', :columns => unknown_columns.join(', '))
      end
      return ''
    end

    def set_article_datas(field, origin_datas, manifestation_type)
      datas = Hash::new
      Manifestation::ARTICLE_COLUMNS.each do |column|
        value = nil
        if field[I18n.t("resource_import_textfile.excel.article.#{column}")]
          value = origin_datas[field[I18n.t("resource_import_textfile.excel.article.#{column}")]]
        end

        case I18n.t("resource_import_textfile.excel.article.#{column}")
        when I18n.t('resource_import_textfile.excel.article.original_title')
          datas.store('original_title', value)
        when I18n.t('resource_import_textfile.excel.article.title')
          datas.store('article_title', value)
        when I18n.t('resource_import_textfile.excel.article.pub_date')
          datas.store('pub_date', value)
        when I18n.t('resource_import_textfile.excel.article.access_address')
          datas.store('access_address', value)
        when I18n.t('resource_import_textfile.excel.article.number_of_page')
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
          datas.store('start_page', start_page)
          datas.store('end_page', end_page)
        when I18n.t('resource_import_textfile.excel.article.volume_number_string')
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
          datas.store('volume_number_string', volume_number_string)
          datas.store('issue_number_string', issue_number_string)
        when I18n.t('resource_import_textfile.excel.article.creator')
          datas.store('creators', manifestation_type.name == 'japanese_article' ? value : value.to_s.gsub(' ', ';'))
        when I18n.t('resource_import_textfile.excel.article.subject')
          datas.store('subjects', manifestation_type.name == 'japanese_article' ? value : value.to_s.gsub(/\*|＊/, ';'))
        when I18n.t('resource_import_textfile.excel.article.call_number')
          datas.store('call_number', value)
        end
      end
      p "---- datas --------------------"
      datas.each { |key, value| p "#{key}: #{value}" }
      return datas
    end

    def import_article_data(import_textresult, field, origin_datas, manifestation_type, textfile, numbering, num)
      datas = set_article_datas(field, origin_datas, manifestation_type)
      check_article_datas_has_necessary_field(field, origin_datas)
      item, mode, error_msg = same_article(datas, manifestation_type)
      import_textresult.error_msg = error_msg if error_msg

      manifestation, m_mode = create_article_manifestation(datas, item, manifestation_type, mode)
      item, i_mode          = create_article_item(datas, manifestation, item, textfile, numbering, mode)

      item.manifestation = manifestation
      import_textresult.manifestation = manifestation
      import_textresult.item          = item
      case m_mode
      when 'create' then num[:manifestation_imported] += 1
      when 'edit'   then num[:manifestation_found] += 1
      end
      case i_mode
      when 'create' then num[:item_imported] += 1
      when 'edit'   then num[:item_found] += 1
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

    def create_article_manifestation(datas, item, manifestation_type, mode = 'edit')
      manifestation = nil 
      if item
         manifestation = item.manifestation
      else       
        mode = 'create'
        manifestation = Manifestation.new(
          :carrier_type   => @article_default_datas[:carrier_type], 
          :language       => @article_default_datas[:language],
          :frequency      => @article_default_datas[:frequency],
          :required_role  => @article_default_datas[:required_role], 
          :except_recent  => @article_default_datas[:except_recent],
          :during_import  => true,
        )
      end
      p mode == 'create' ? "create new manifestation" : "edit manifestation / id:#{manifestation.id}" 

      manifestation.manifestation_type = manifestation_type
      datas.each do |key, value|
        unless ['call_number', 'creators', 'subjects'].include?(key)
          manifestation[key] = value.to_s unless value.nil?
        end
      end
      manifestation.save!
      manifestation.creators = Patron.add_patrons(datas['creators'].to_s) unless datas['creators'].nil?
      manifestation.subjects = Subject.import_subjects(datas['subjects'].to_s) unless datas['subjects'].nil?
      return manifestation, mode
    end

    def create_article_item(datas, manifestation, item, textfile, numbering, mode = 'edit')
      unless item 
        if manifestation.items.size < 1
          mode = 'create'
          item = Item.new
        else
          item = manifestation.items.order('created_at asc').first
        end
      end
      p mode == 'create' ? "create new item" : "edit item / id: #{item.id} / item_identifer: #{item.item_identifier}"

      item.circulation_status = @article_default_datas[:circulation_status]
      item.use_restriction    = @article_default_datas[:use_restriction]
      item.checkout_type      = @article_default_datas[:checkout_type]
      item.rank               = @article_default_datas[:rank]
      item.shelf_id           = textfile.user.library.article_shelf.id
      item.call_number        = datas['call_number'].to_s unless datas['call_number'].nil?
      while item.item_identifier.nil?
        item_identifier = Numbering.do_numbering(numbering.name)
        item.item_identifier   = item_identifier unless Item.where(:item_identifier => item_identifier).first
      end
      item.save!
      item.patrons << textfile.user.library.patron if mode == 'create'
      return item, mode
    end

    def same_article(datas, manifestation_type)
      conditions = ["((manifestations).manifestation_type_id = \'#{manifestation_type.id}\')"]
      datas.each do |key, value|
        case key
        when 'creators', 'subjects'
          conditions << "#{key == 'creators' ? 'creates' : 'subjects'}.id IS #{'NOT' unless value.nil? or value.blank?} NULL"
        else
          model = 'manifestations'
          model = 'items' if key == 'call_number'
          if value.nil? or value.blank?
            conditions << "((#{model}).#{key} IS NULL OR (#{model}).#{key} = '')"
          else
            conditions << "((#{model}).#{key} = \'#{value.to_s.gsub("'", "''")}\')"
          end 
        end
      end
      conditions = conditions.join(' AND ')
      p "---- conditions --------------------"
      p conditions

      articles = Item.find(
        :all,
        :include => [:manifestation => [:creators, :subjects]],
        :conditions => conditions,
        :order => "items.created_at asc"
      )
      if articles
        creators = datas['creators'].to_s.gsub('；', ';').split(/;/).sort rescue []
        subjects = datas['subjects'].to_s.gsub('；', ';').split(/;/).sort rescue []
        same_articles = []
        articles.each do |article|
          a_creators = article.manifestation.creators.pluck(:full_name).sort rescue []
          a_subjects = article.manifestation.subjects.pluck(:term).sort rescue []
          same_articles << article if a_creators == creators and a_subjects == subjects
        end
        if same_articles.size > 1
          # 書誌同定で対象となる本が複数存在する場合は新規作成とする
          error_msg = I18n.t('resource_import_textfile.error.book.exist_multiple_same_manifestations')
          return nil, nil, error_msg
        elsif same_articles.size == 1
          return same_articles.first, 'edit', nil
        end
      end
      return nil, nil, nil
    end
  end
end

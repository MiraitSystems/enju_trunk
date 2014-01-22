# -*- encoding: utf-8 -*-
require File.join(File.expand_path(File.dirname(__FILE__)), 'import_book')
require File.join(File.expand_path(File.dirname(__FILE__)), 'import_article')
class ResourceImport < EnjuTrunk::ResourceAdapter::Base
  include EnjuTrunk::ImportBook
  include EnjuTrunk::ImportArticle

  READ_ARTICLE = lambda do |manifestation_type| 
      (SystemConfiguration.get('manifestations.split_by_type') and manifestation_type.is_article?) ? true : false
    end

  def import(params)
    adapter = EnjuTrunk::ResourceAdapter::Base.find_by_classname(params.adapter_name)
    adapter.logger = logger
    logger.info "adapter=#{adapter.to_s}"
    logger.info "start import: #{Time.now}"

    Benchmark.bm do |x|
      x.report {
        textfile_id = params.id
        resource_import_textfile = ResourceImportTextfile.find(textfile_id)
        extraparams = eval(params.extraparams)
        filename = params.resource_import_text.path

        @article_default_datas = set_article_default_datas
          
        case params.adapter_name
        when 'Tsvfile_Adapter'
          import_textresult = ResourceImportTextresult.new(resource_import_textfile_id: textfile_id, failed: true)
          begin
            logger.info "start read"
            check_format = Tsvfile_Adapter.new.check_format(filename)
            manifestation_type = get_manifestation_type_from_data(extraparams["manifestation_type"].first)
            auto_numbering     = extraparams["auto_numbering"].first
            numbering          = ResourceImport.set_numbering(extraparams["numbering"].first, manifestation_type)
            file = Tsvfile_Adapter.new.open_import_file(filename)
            field, datas = Tsvfile_Adapter.new.set_datas(file)
            read_data(field, manifestation_type, resource_import_textfile, numbering, auto_numbering, import_textresult, { datas: datas })
          rescue => e
            logger.info e.message
            import_textresult.error_msg = e.message
            fp = open(filename, 'r')
            row_num = 0
            while fp.gets
              row_num += 1
            end
            import_textresult.extraparams = "{'wrong_format' => true, 'row_num' => #{ row_num }, 'filename' => '#{filename}' }" 
            import_textresult.save
          end
        when 'Excelfile_Adapter'
          oo = Excelx.new(filename)
          extraparams["sheet"].each_with_index do |sheet, i|
            import_textresult = ResourceImportTextresult.new(resource_import_textfile_id: textfile_id, failed: true)
            begin
              oo.default_sheet = sheet
              logger.info "start read sheet: #{oo.default_sheet}"

              manifestation_type = get_manifestation_type_from_data(extraparams["manifestation_type"][i].to_i)
              auto_numbering     = extraparams["auto_numbering"][i]
              numbering          = ResourceImport.set_numbering(extraparams["numbering"][i], manifestation_type)
              logger.info "manifestation_type: #{manifestation_type.display_name}" if manifestation_type

              field_row_num = READ_ARTICLE.call(manifestation_type) ? ARTICLE_HEADER_ROW : BOOK_HEADER_ROW
              field = Excelfile_Adapter.new.set_field(oo, sheet, manifestation_type, field_row_num)
              read_data(field, manifestation_type, resource_import_textfile, numbering, auto_numbering, import_textresult, { oo: oo })
            rescue => e
              logger.info e.message
              import_textresult.error_msg   =  I18n.t('resource_import_textfile.error.failed_to_read_sheet', :sheet => sheet)
              import_textresult.error_msg  += "<br />#{e.message}"
              import_textresult.extraparams = "{'sheet'=>'#{sheet}', 'wrong_sheet' => true, 'row_num' => #{oo.last_column.to_i}, 'filename' => '#{filename}' }"
              import_textresult.save!
              next
            end
          end
        end
      }
    end 
    logger.info "end import: #{Time.now}"
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

  # DBにmanifestation_typeが入っている必要があるとき
  def get_manifestation_type_from_data(manifestation_type_id)
    return nil unless SystemConfiguration.get('manifestations.split_by_type')
    manifestation_type = ManifestationType.find(manifestation_type_id) rescue nil
    if manifestation_type.nil?
      raise I18n.t('resource_import_textfile.error.manifestation_type_is_nil')
    end
    return manifestation_type
  end

  def check_sheet_can_import(field, manifestation_type, options = { oo: nil, datas: nil })
    if READ_ARTICLE.call(manifestation_type)
      check_article_header_has_necessary_field(field)
    else
      check_book_header_has_manifestation_type(field)
      check_book_header_has_necessary_field(field, manifestation_type)
      check_duplicate_item_identifier(field, options)
    end
  end

  def fix_data(cell)
    return nil unless cell
    cell = cell.to_s.strip

    if cell.match(/^[0-9]+.0$/)
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

  def read_data(field, manifestation_type, textfile, numbering, auto_numbering, import_textresult, options = { oo: nil, datas: nil })
    default_sheet = options[:oo] ? options[:oo].default_sheet : nil
    check_sheet_can_import(field, manifestation_type, { oo: options[:oo], datas: options[:datas] })

    # message: import start
    create_import_start_message(field, manifestation_type, import_textresult, default_sheet)

    num = {
      :manifestation_imported => 0,
      :item_imported          => 0,
      :manifestation_found    => 0,
      :item_found             => 0,
      :failed                 => 0
    }

    # start import data row.
    data_row_num = READ_ARTICLE.call(manifestation_type) ? ARTICLE_DATA_ROW : BOOK_DATA_ROW
    if options[:oo]
      data_row_num.upto(options[:oo].last_row) do |row_num|
        origin_datas = Hash::new
        options[:oo].first_column.upto(options[:oo].last_column) do |column|
          origin_datas.store(column, fix_data(options[:oo].cell(row_num, column).to_s.strip))
        end
        num = import_datas(field, origin_datas, row_num, textfile, num, manifestation_type, numbering, auto_numbering, { sheet: options[:oo].default_sheet } )
      end
    else
      options[:datas].each_with_index do |row, row_num|
        origin_datas = Hash::new
        row.each_with_index { |column, c| origin_datas.store(c, fix_data(column.to_s.strip)) }
        # 2行目からデータ行なので row_num を +2 する
        num = import_datas(field, origin_datas, row_num + 2, textfile, num, manifestation_type, numbering, auto_numbering) 
      end
    end
    Sunspot.commit
    Rails.cache.write("manifestation_search_total", Manifestation.search.total)

    # message: import end
    create_import_end_message(num, textfile, default_sheet)
  end

  def import_datas(field, origin_datas, row_num, textfile, num, manifestation_type, numbering, auto_numbering, options = { sheet: nil })
    logger.info "import start row_num=#{row_num}"
    import_textresult = ResourceImportTextresult.new(resource_import_textfile_id: textfile.id, body: origin_datas.values.join("\t"))
    import_textresult.extraparams = "{'sheet'=>'#{options[:sheet]}'}" if options[:sheet]

    begin
      ActiveRecord::Base.transaction do
        #TODO do refactring -- start --
        if READ_ARTICLE.call(manifestation_type)
          import_article_data(import_textresult, field, origin_datas, manifestation_type, textfile, numbering, num)
        else
          import_book_data(import_textresult, field, origin_datas, manifestation_type, textfile, numbering, auto_numbering, num, { seet: options[:sheet] })
        end
        #TODO do refactring -- end --
      end
    rescue => e
      import_textresult.failed     = true
      import_textresult.error_msg  = options[:sheet] ? "FAIL[sheet:#{options[:sheet]} row:#{row_num}]: " : "FAIL[row:#{row_num}]: "
      import_textresult.error_msg += e.message
      Rails.logger.info(import_textresult.error_msg)
      logger.info import_textresult.error_msg
      num[:failed] += 1
    end
    import_textresult.save!
    if row_num % 50 == 0
      Sunspot.commit and GC.start
    end
    return num
  end

  def create_import_start_message(field, manifestation_type, import_textresult, default_sheet = nil)
    import_textresult.extraparams = "{'sheet'=>'#{default_sheet}'}" if default_sheet
    import_textresult.body        = field.keys.join("\t")
    import_textresult.error_msg   = I18n.t('resource_import_textfile.message.read_start')
    import_textresult.error_msg  += I18n.t('resource_import_textfile.message.sheet_info', :sheet => default_sheet) if default_sheet
    import_textresult.error_msg  += READ_ARTICLE.call(manifestation_type) ? article_header_has_out_of_manage?(field) : book_header_has_out_of_manage?(field)
    import_textresult.save!
  end

  def create_import_end_message(num, textfile, default_sheet = nil)
    msg  = I18n.t('resource_import_textfile.message.read_end') 
    msg += I18n.t('resource_import_textfile.message.sheet_info', :sheet => default_sheet) if default_sheet
    msg += "
      <br />
      #{I18n.t('resource_import_textfile.message.manifestation_imported')}: #{num[:manifestation_imported]}
      #{I18n.t('resource_import_textfile.message.item_imported')}: #{num[:item_imported]}
      #{I18n.t('resource_import_textfile.message.manifestation_found')}: #{num[:manifestation_found]}
      #{I18n.t('resource_import_textfile.message.item_found')}: #{num[:item_found]}
      #{I18n.t('resource_import_textfile.message.failed')}: #{num[:failed]}
    "
    import_textresult = ResourceImportTextresult.create(
      failed: false,
      resource_import_textfile_id: textfile.id,
      error_msg: msg,
      extraparams: "{'not_read' => true}"
    )
  end
end
EnjuTrunk::ResourceAdapter::Base.add(ResourceImport)

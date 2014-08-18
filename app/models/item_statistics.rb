# encoding: utf-8
class ItemStatistics
  include ActiveModel::Conversion
  include ActiveModel::Validations
  extend ActiveModel::Naming
  extend ActiveModel::Translation

  def initialize(attributes = {})
    attributes.each do |name, value|
      send("#{name}=", value) rescue nil
    end
  end
  
  def persisted? ; false ; end
  
  attr_accessor :statistical_table_type, :acquired_at_from, :acquired_at_to, :aggregation_type,
                :money_aggregation, :remove_aggregation,
                :library_id, :output_condition,
                :first_aggregation, :second_aggregation

  validates_presence_of :acquired_at_from
  validates_presence_of :acquired_at_to
  validate :acquired_at_from_valid?
  validate :acquired_at_to_valid?
  validate :acquired_at_range_valid?
  
  def self.aggregation_types
    return I18n.t('statistical_table.item_statistics.aggregation_type').map{|k,v|[v,k]}
  end

  def self.first_aggregations
    return I18n.t('statistical_table.item_statistics.first_aggregation').map{|k,v|[v,k]}
  end

  def self.second_aggregations
    return [[I18n.t('statistical_table.item_statistics.first_aggregation.budget_category_group'), "budget_category_group"]]
  end

  def make_data
    items = Item.select("items.id")
    items = items.joins(:manifestation)
    items = items.joins(:budget_category)
    items = items.joins(:shelf)
    
    if self.money_aggregation == "1"
      self.money_aggregation = true
    else
      self.money_aggregation = false
    end
    if self.remove_aggregation == "1"
      self.remove_aggregation = true
    else
      self.remove_aggregation = false
    end

    # 集計日付を求める
    if md = self.acquired_at_from.match(/^([0-9]{4})-([0-9]{2})$/)
      acquired_at_from = "#{md[1]}-#{md[2]}-01"
    else
      acquired_at_from = self.acquired_at_from
    end
    if md = self.acquired_at_to.match(/^([0-9]{4})-([0-9]{2})$/)
      day = Date.new(md[1].to_i, md[2].to_i, 1).end_of_month
      acquired_at_to = day.to_s
    else
      acquired_at_to = self.acquired_at_to
    end
    from_date_obj = Date.parse(acquired_at_from)
    to_date_obj = Date.parse(acquired_at_to)
    items = items.where("acquired_at >= ? and acquired_at <= ?", from_date_obj.beginning_of_day, to_date_obj.end_of_day)
    
    # 図書館
    if self.library_id.present?
      items = items.where("shelves.library_id = ?", self.library_id)
    end
    
    # 出力条件 ItemExinfo
#    if Rails.application.class.parent_name == "EnjuWilmina"
#      items = items.where("items.asset_category_id = ?", self.output_condition)
#    end

    # 横軸
    if self.second_aggregation == "budget_category_group"
      col_column = "budget_categories.group_id"
      cols =  Keycode.where(:name => 'budget_category.group')
    end

    # 縦軸１
    if self.aggregation_type.present?
      if self.aggregation_type == "statistical_class"
        first_row_column = "items.statistical_class_id"
  #      first_rows = Keycode.where(:name => 'item.statistical_class')
        first_rows = Keycode.where(:name => 'item.statistical_class').limit(2) # for debug
      elsif self.aggregation_type == "manifestation_type"
        first_row_column = "manifestations.manifestation_type_id"
        first_rows = ManifestationType.all
      end
    else
      first_rows = ["blank"]
    end
    
    # 縦軸２
    if self.first_aggregation == "budget_category_group"
      second_row_column = "budget_categories.group_id"
      second_rows = Keycode.where(:name => 'budget_category.group')
    elsif self.first_aggregation == "carrier_type"
      second_row_column = "manifestations.carrier_type_id"
      second_rows = CarrierType.all
    end

    data = []

    first_rows.each do |first_row|
      if first_row == "blank"
        first_items = items
      else
        first_items = items.where("#{first_row_column} = ?", first_row.id)
      end
      second_row_details = []
      sum_detail = {:jpn_not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                    :foreign_not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                    :jpn_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                    :foreign_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                    :not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                    :donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0}}
      
      unless cols.blank?
        sum_details = []
        record_count = cols.length + 1 # +1は未設定分
        record_count.times do
          sum_details << sum_detail
        end
      end

      second_rows.each do |second_row|
        # 条件
        second_items = first_items.where("#{second_row_column} = ?", second_row.id)
        
        # 横軸集計
        if cols.blank?
          detail = make_detail_data(self, second_items)
          # 小計の加算
          detail.each do |key, value|
            value.each do |k, v|
              sum_detail[key][k] += v
            end
          end
          if self.first_aggregation == "budget_category_group"
            second_row_details << {:second_row_name => second_row.keyname, :detail => detail}
          elsif self.first_aggregation == "carrier_type"
            second_row_details << {:second_row_name => second_row.display_name, :detail => detail}
          end
        else # cols.blank? == false
          details = []
          cols.each do |col|
            third_items = second_items.where("#{col_column} = ?", col.id)
            details << make_detail_data(self, third_items)
          end
          # 小分類未設定分
          third_items = second_items.where("#{col_column} is null")
          details << make_detail_data(self, third_items)
          # 小計の加算
          details.each_with_index do |detail, index|
            detail.each do |key, value|
              value.each do |k, v|
                sum_details[index][key][k] += v
              end
            end
          end
          if self.first_aggregation == "budget_category_group"
            second_row_details << {:second_row_name => second_row.keyname, :detail => details}
          elsif self.first_aggregation == "carrier_type"
            second_row_details << {:second_row_name => second_row.display_name, :detail => details}
          end
        end
      end # second_rows
      # 中分類未設定分
      if cols.blank?
        second_items = first_items.where("#{second_row_column} is null")
        detail = make_detail_data(self, second_items)
        # 小計の加算
        detail.each do |key, value|
          value.each do |k, v|
            sum_detail[key][k] += v
          end
        end
        second_row_details << {:second_row_name => I18n.t("statistical_table.item_statistics.first_aggregation.#{self.first_aggregation}") + I18n.t('statistical_table.aggregation_other'), :detail => detail}
      end

      # 小計行の追加
      if cols.blank?
        second_row_details << {:second_row_name => I18n.t('statistical_table.subtotal'), :detail => sum_detail}
      else
        second_row_details << {:second_row_name => I18n.t('statistical_table.subtotal'), :detail => sum_details}
      end
      
      if self.aggregation_type == "statistical_class"
        data << {:first_row_name => first_row.keyname, :second_row_details => second_row_details}
      elsif self.aggregation_type == "manifestation_type"
        data << {:first_row_name => first_row.display_name, :second_row_details => second_row_details}
      else
        data << {:second_row_details => second_row_details}
      end
    end # first_rows

    conditions = self
    conditions.acquired_at_from = acquired_at_from
    conditions.acquired_at_to = acquired_at_to
    
    columns = []
    if cols.present?
      cols.each do |col|
        columns << col.keyname
      end
      columns << I18n.t("statistical_table.aggregation_third_classes.#{self.second_aggregation}") + I18n.t('statistical_table.aggregation_other')
    end
    
    return {:data => data, :conditions => conditions, :cols => columns}
  end

  def self.output_excelx(output_data, filename = nil)
    require 'axlsx'

    # initialize
    if filename.present?
      # 定期作成
      out_dir = "#{Rails.root}/private/system/item_statistics"
      excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{filename}.xlsx"
    else
      # 手動作成
      out_dir = "#{Rails.root}/private/user_file/item_statistics"
      excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{rand(10)}.xlsx"
    end
    FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)

    Rails.logger.info "output_item_statistics_excelx filepath=#{excel_filepath}"

    conditions = output_data[:conditions]
    
    Axlsx::Package.new do |p|
      wb = p.workbook
      wb.styles do |s|
        sheet = wb.add_worksheet(:name => I18n.t('activemodel.models.item_statistics'))
        top_style = s.add_style :font_name => Setting.item_statistics_print_excelx.fontname, :sz => 16, :alignment => {:horizontal => :center, :vertical => :center}
        merge_style = s.add_style :font_name => Setting.item_statistics_print_excelx.fontname, :alignment => {:horizontal => :center, :vertical => :center}
        default_style = s.add_style :font_name => Setting.item_statistics_print_excelx.fontname
        
        # ヘッダ
        sheet.add_row [I18n.t('activemodel.models.item_statistics')], :types => :string, :style => top_style
        sheet.merge_cells "A1:O1"

        condition = [I18n.t('statistical_table.output_date') + ":"]
        condition << Date.today
        sheet.add_row condition, :types => :string, :style => default_style
        condition = [I18n.t('activerecord.attributes.item.acquired_at') + ":"]
        condition << conditions.acquired_at_from
        condition << "～"
        condition << conditions.acquired_at_to
        sheet.add_row condition, :types => :string, :style => default_style
        condition = [I18n.t('activerecord.models.library') + ":"]
        if conditions.library_id.present?
          library = Library.where(:id => conditions.library_id).first
          condition << library.display_name
        else
          condition << I18n.t('advanced_search.all_libraries')
        end
        sheet.add_row condition, :types => :string, :style => default_style
        condition = [I18n.t('activemodel.attributes.item_statistics.output_condition') + ":"]
        if conditions.output_condition.present?
          output_condition = Keycode.where(:id => conditions.output_condition).first
          condition << output_condition.keyname
        else
          condition << ""
        end
        sheet.add_row condition, :types => :string, :style => default_style
        condition = [I18n.t('statistical_table.aggregation_first') + ":"]
        if conditions.aggregation_type.present?
          condition << I18n.t("statistical_table.item_statistics.aggregation_type.#{conditions.aggregation_type}")
        else
          condition << ""
        end
        sheet.add_row condition, :types => :string, :style => default_style
        condition = [I18n.t('statistical_table.aggregation_second') + ":"]
        if conditions.first_aggregation.present?
          condition << I18n.t("statistical_table.item_statistics.first_aggregation.#{conditions.first_aggregation}")
        else
          condition << ""
        end
        sheet.add_row condition, :types => :string, :style => default_style
        condition = [I18n.t('statistical_table.aggregation_third') + ":"]
        if conditions.second_aggregation.present?
          condition << I18n.t("statistical_table.item_statistics.first_aggregation.budget_category_group")
        else
          condition << ""
        end
        sheet.add_row condition, :types => :string, :style => default_style
        if conditions.money_aggregation.present?
          sheet.add_row [I18n.t('statistical_table.money_aggregation')], :types => :string, :style => default_style
        end
        if conditions.remove_aggregation.present?
          sheet.add_row [I18n.t('statistical_table.remove_aggregation')], :types => :string, :style => default_style
        end

        sheet.add_row [], :types => :string, :style => default_style

        # 明細
        if conditions.remove_aggregation.present?
          # 除籍を除く
          sheet.add_row [I18n.t('statistical_table.item_not_remove')], :types => :string, :style => default_style
          self.output_columns(s, sheet, conditions, output_data[:cols])
          self.output_detail(s, sheet, output_data[:data], conditions, output_data[:cols], "item_not_remove")
          sheet.add_row [], :types => :string, :style => default_style
          # 除籍資料
          sheet.add_row [I18n.t('statistical_table.item_remove')], :types => :string, :style => default_style
          self.output_columns(s, sheet, conditions, output_data[:cols])
          self.output_detail(s, sheet, output_data[:data], conditions, output_data[:cols], "item_remove")
        else
          # 項目名の出力
          self.output_columns(s, sheet, conditions, output_data[:cols])
          # データの出力
          self.output_detail(s, sheet, output_data[:data], conditions, output_data[:cols])
        end
        
        p.serialize(excel_filepath)
      end
    end
    return excel_filepath
  end

private

  def acquired_at_from_valid?
    if acquired_at_from.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_from || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_from
        errors.add(:acquired_at_from)
      end
    end
  end

  def acquired_at_to_valid?
    if acquired_at_to.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_to || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_to
        errors.add(:acquired_at_to)
      end
    end
  end

  def acquired_at_range_valid?
    if acquired_at_from.present? && acquired_at_to.present?
      if (/^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_from && /^[0-9]{4}-[0-9]{2}$/ =~ acquired_at_to) || (/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_from && /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ acquired_at_to)
      
        if acquired_at_from > acquired_at_to
          errors.add(:acquired_at_from)
        end
      else
        errors.add(:acquired_at_from)
      end
    end
  end

  def make_detail_data(item_statistics, second_items)
    detail = {:jpn_not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
              :foreign_not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
              :jpn_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
              :foreign_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
              :not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
              :donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0}}
    if item_statistics.remove_aggregation == true
      # 和書 寄贈以外
      jpn_not_donates = second_items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id not in (?)", AcceptType.donate)
      jpn_not_donate_presents = jpn_not_donates.where("items.circulation_status_id not in (?)", CirculationStatus.removed).uniq
      jpn_not_donate_removes = jpn_not_donates.where("items.circulation_status_id in (?)", CirculationStatus.removed).uniq
      detail[:jpn_not_donate][:book] = jpn_not_donate_presents.length
      detail[:jpn_not_donate][:book_remove] = jpn_not_donate_removes.length
      # 洋書 寄贈以外
      foreign_not_donates = second_items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id not in (?)", AcceptType.donate)
      foreign_not_donate_presents = foreign_not_donates.where("items.circulation_status_id not in (?)", CirculationStatus.removed).uniq
      foreign_not_donate_removes = foreign_not_donates.where("items.circulation_status_id in (?)", CirculationStatus.removed).uniq
      detail[:foreign_not_donate][:book] = foreign_not_donate_presents.length
      detail[:foreign_not_donate][:book_remove] = foreign_not_donate_removes.length
      # 和書 寄贈
      jpn_donates = second_items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id in (?)", AcceptType.donate)
      jpn_donate_presents = jpn_donates.where("items.circulation_status_id not in (?)", CirculationStatus.removed).uniq
      jpn_donate_removes = jpn_donates.where("items.circulation_status_id in (?)", CirculationStatus.removed).uniq
      detail[:jpn_donate][:book] = jpn_donate_presents.length
      detail[:jpn_donate][:book_remove] = jpn_donate_removes.length
      # 洋書 寄贈
      foreign_donates = second_items.where("manifestations.jpn_or_foreign = 1 and items.accept_type_id in (?)", AcceptType.donate)
      foreign_donate_presents = foreign_donates.where("items.circulation_status_id not in (?)", CirculationStatus.removed).uniq
      foreign_donate_removes = foreign_donates.where("items.circulation_status_id in (?)", CirculationStatus.removed).uniq
      detail[:foreign_donate][:book] = foreign_donate_presents.length
      detail[:foreign_donate][:book_remove] = foreign_donate_removes.length
      # 合計
      detail[:not_donate][:book] = jpn_not_donate_presents.length + foreign_not_donate_presents.length
      detail[:not_donate][:book_remove] = jpn_not_donate_removes.length + foreign_not_donate_removes.length
      detail[:donate][:book] = jpn_donate_presents.length + foreign_donate_presents.length
      detail[:donate][:book_remove] = jpn_donate_removes.length + foreign_donate_removes.length
      # 金額の算出
      if item_statistics.money_aggregation == true
        detail[:jpn_not_donate][:price] = jpn_not_donate_presents.present? ? Item.sum(:price, :conditions => {:id => jpn_not_donate_presents}) : 0
        detail[:jpn_not_donate][:price_remove] = jpn_not_donate_removes.present? ? Item.sum(:price, :conditions => {:id => jpn_not_donate_removes}) : 0
        detail[:foreign_not_donate][:price] = foreign_not_donate_presents.present? ? Item.sum(:price, :conditions => {:id => foreign_not_donate_presents}) : 0
        detail[:foreign_not_donate][:price_remove] = foreign_not_donate_removes.present? ? Item.sum(:price, :conditions => {:id => foreign_not_donate_removes}) : 0
        detail[:jpn_donate][:price] = jpn_donate_presents.present? ? Item.sum(:price, :conditions => {:id => jpn_donate_presents}) : 0
        detail[:jpn_donate][:price_remove] = jpn_donate_removes.present? ? Item.sum(:price, :conditions => {:id => jpn_donate_removes}) : 0
        detail[:foreign_donate][:price] = foreign_donate_presents.present? ? Item.sum(:price, :conditions => {:id => foreign_donate_presents}) : 0
        detail[:foreign_donate][:price_remove] = foreign_donate_removes.present? ? Item.sum(:price, :conditions => {:id => foreign_donate_removes}) : 0
        detail[:not_donate][:price] = detail[:jpn_not_donate][:price] + detail[:foreign_not_donate][:price]
        detail[:not_donate][:price_remove] = detail[:jpn_not_donate][:price_remove] + detail[:foreign_not_donate][:price_remove]
        detail[:donate][:price] = detail[:jpn_donate][:price] + detail[:foreign_donate][:price]
        detail[:donate][:price_remove] = detail[:jpn_donate][:price_remove] + detail[:foreign_donate][:price_remove]
      end
    else
      # 和書 寄贈以外
      jpn_not_donates = second_items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id not in (?)", AcceptType.donate).uniq
      detail[:jpn_not_donate][:book] = jpn_not_donates.length
      # 洋書 寄贈以外
      foreign_not_donates = second_items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id not in (?)", AcceptType.donate).uniq
      detail[:foreign_not_donate][:book] = foreign_not_donates.length
      # 和書 寄贈
      jpn_donates = second_items.where("manifestations.jpn_or_foreign = 0 and items.accept_type_id in (?)", AcceptType.donate).uniq
      detail[:jpn_donate][:book] = jpn_donates.length
      # 洋書 寄贈
      foreign_donates = second_items.where("manifestations.jpn_or_foreign = 1 and items.accept_type_id in (?)", AcceptType.donate).uniq
      detail[:foreign_donate][:book] = foreign_donates.length
      # 合計
      detail[:not_donate][:book] = jpn_not_donates.length + foreign_not_donates.length
      detail[:donate][:book] = jpn_not_donates.length + foreign_not_donates.length
      # 金額の算出
      if item_statistics.money_aggregation == true
        detail[:jpn_not_donate][:price] = jpn_not_donates.present? ? Item.sum(:price, :conditions => {:id => jpn_not_donates}) : 0
        detail[:foreign_not_donate][:price] = foreign_not_donates.present? ? Item.sum(:price, :conditions => {:id => foreign_not_donates}) : 0
        detail[:jpn_donate][:price] = jpn_donates.present? ? Item.sum(:price, :conditions => {:id => jpn_donates}) : 0
        detail[:foreign_donate][:price] = foreign_donates.present? ? Item.sum(:price, :conditions => {:id => foreign_donates}) : 0
        detail[:not_donate][:price] = detail[:jpn_not_donate][:price] + detail[:foreign_not_donate][:price]
        detail[:donate][:price] = detail[:jpn_donate][:price] + detail[:foreign_donate][:price]
      end
    end
    return detail
  end
  
  # 項目名の出力
  def self.output_columns(wbstyles, sheet, conditions, cols)
    merge_style = wbstyles.add_style :font_name => Setting.item_statistics_print_excelx.fontname, :alignment => {:horizontal => :center, :vertical => :center}
    if cols.length > 0
      # 1行目
      if conditions.aggregation_type.present?
        columns = [""]
      else
        columns = []
      end
      columns << ""
      # 寄贈以外
      cols.each do |col|
        columns << col
        2.times{ columns << "" }
        3.times{ columns << "" } if conditions.money_aggregation.present?
      end
      columns << I18n.t('statistical_table.subtotal')
      columns << "" if conditions.money_aggregation.present?
      # 寄贈
      cols.each do |col|
        columns << col
        2.times{ columns << "" }
        3.times{ columns << "" } if conditions.money_aggregation.present?
      end
      columns << I18n.t('statistical_table.subtotal')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.total')
      columns << "" if conditions.money_aggregation.present?
      sheet.add_row columns, :types => :string, :style => merge_style
      # セル結合
      # 寄贈以外
      start_col = conditions.aggregation_type.present? ? 2 : 1
      step_col = conditions.money_aggregation.present? ? 6 : 3
      from = 0
      to = 0
      cols.each_with_index do |col, i|
        from = start_col + (step_col * i)
        to = start_col + step_col + (step_col * i) - 1
        sheet.merge_cells sheet.rows.last.cells[from..to]
      end
      if conditions.money_aggregation.present?
        from = to + 1
        to = from + 1
        sheet.merge_cells sheet.rows.last.cells[from..to]
      else
        to += 1
      end
      # 寄贈
      start_col = to + 1
      cols.each_with_index do |col, i|
        from = start_col + (step_col * i)
        to = start_col + step_col + (step_col * i) - 1
        sheet.merge_cells sheet.rows.last.cells[from..to]
      end
      2.times do
        if conditions.money_aggregation.present?
          from = to + 1
          to = from + 1
          sheet.merge_cells sheet.rows.last.cells[from..to]
        end
      end
      
      # 2行目
      if conditions.aggregation_type.present?
        columns = [""]
      else
        columns = []
      end
      columns << ""
      cols.each_with_index do |col, i|
        columns << I18n.t('statistical_table.jpn')
        columns << "" if conditions.money_aggregation.present?
        columns << I18n.t('statistical_table.foreign')
        columns << "" if conditions.money_aggregation.present?
        columns << I18n.t('statistical_table.subtotal')
        columns << "" if conditions.money_aggregation.present?
      end
      columns << ""
      columns << "" if conditions.money_aggregation.present?
      cols.each_with_index do |col, i|
        columns << I18n.t('statistical_table.jpn_donate')
        columns << "" if conditions.money_aggregation.present?
        columns << I18n.t('statistical_table.foreign_donate')
        columns << "" if conditions.money_aggregation.present?
        columns << I18n.t('statistical_table.total_donate')
        columns << "" if conditions.money_aggregation.present?
      end
      2.times do
        columns << ""
        columns << "" if conditions.money_aggregation.present?
      end
      sheet.add_row columns, :types => :string, :style => merge_style
      # セル結合
      if conditions.money_aggregation.present?
        start_col = conditions.aggregation_type.present? ? 2 : 1
        loops = cols.length * 3 * 2 + 3
        loops.times do |i|
          from = start_col + 2 * i
          to = start_col + 1 + 2 * i
          sheet.merge_cells sheet.rows.last.cells[from..to]
        end
      end
      
      # 3行目
      if conditions.aggregation_type.present?
        columns = [I18n.t("statistical_table.item_statistics.aggregation_type.#{conditions.aggregation_type}")]
      else
        columns = []
      end
      columns << I18n.t("statistical_table.item_statistics.first_aggregation.#{conditions.first_aggregation}")
      loops = cols.length * 3 * 2 + 3
      loops.times do
        columns << I18n.t('statistical_table.books')
        columns << I18n.t('statistical_table.prices') if conditions.money_aggregation.present?
      end
      sheet.add_row columns, :types => :string, :style => merge_style
    else
      # 1行目
      if conditions.aggregation_type.present?
        columns = [""]
      else
        columns = []
      end
      columns << ""
      columns << I18n.t('statistical_table.jpn')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.foreign')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.subtotal')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.jpn_donate')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.foreign_donate')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.total_donate')
      columns << "" if conditions.money_aggregation.present?
      columns << I18n.t('statistical_table.total')
      columns << "" if conditions.money_aggregation.present?
      sheet.add_row columns, :types => :string, :style => merge_style
      if conditions.money_aggregation.present?
        start_col = conditions.aggregation_type.present? ? 2 : 1
        7.times do |i|
          from = start_col + 2 * i
          to = start_col + 1 + 2 * i
          sheet.merge_cells sheet.rows.last.cells[from..to]
        end
      end
      
      # 2行目
      if conditions.aggregation_type.present?
        columns = [I18n.t("statistical_table.item_statistics.aggregation_type.#{conditions.aggregation_type}")]
      else
        columns = []
      end
      columns << I18n.t("statistical_table.item_statistics.first_aggregation.#{conditions.first_aggregation}")
      7.times do |i|
        columns << I18n.t('statistical_table.books')
        columns << I18n.t('statistical_table.prices') if conditions.money_aggregation.present?
      end
      sheet.add_row columns, :types => :string, :style => merge_style
    end
  end
  
  # データの出力
  def self.output_detail(wbstyles, sheet, data, conditions, cols, remove = nil)
    default_style = wbstyles.add_style :font_name => Setting.item_statistics_print_excelx.fontname

    if remove.blank?
      book_sym = "book".to_sym
      price_sym = "price".to_sym
    else
      if remove == "item_not_remove"
        book_sym = "book".to_sym
        price_sym = "price".to_sym
      else
        book_sym = "book_remove".to_sym
        price_sym = "price_remove".to_sym
      end
    end

    if conditions.aggregation_type.present?
      grand_total = {:jpn_not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                     :foreign_not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                     :jpn_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                     :foreign_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                     :not_donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0},
                     :donate => {:book => 0, :price => 0, :book_remove => 0, :price_remove => 0}}
      if cols.present?
        grand_totals = []
        record_count = cols.length
        record_count.times do
          grand_totals << grand_total
        end
      end
    end
    
    data.each do |datum|
      datum[:second_row_details].each_with_index do |second_row, index|
        books_row = []
        if conditions.aggregation_type.present?
          if index == 0
            books_row = [datum[:first_row_name]]
          else
            books_row = [""]
          end
        end
        books_row << second_row[:second_row_name]
        total_book = 0
        total_price = 0
        if second_row[:detail].instance_of?(Array)
          sum_not_donate_book = 0
          sum_not_donate_price = 0
          sum_donate_book = 0
          sum_donate_price = 0
          # 寄贈以外
          second_row[:detail].each do |detail|
            books_row << detail[:jpn_not_donate][book_sym]
            books_row << detail[:jpn_not_donate][price_sym] if conditions.money_aggregation.present?
            books_row << detail[:foreign_not_donate][book_sym]
            books_row << detail[:foreign_not_donate][price_sym] if conditions.money_aggregation.present?
            books_row << detail[:not_donate][book_sym]
            books_row << detail[:not_donate][price_sym] if conditions.money_aggregation.present?
            sum_not_donate_book += detail[:not_donate][book_sym]
            sum_not_donate_price += detail[:not_donate][price_sym] if conditions.money_aggregation.present?
          end
          books_row << sum_not_donate_book
          books_row << sum_not_donate_price if conditions.money_aggregation.present?
          total_book += sum_not_donate_book
          total_price += sum_not_donate_price if conditions.money_aggregation.present?
          # 寄贈
          second_row[:detail].each do |detail|
            books_row << detail[:jpn_donate][book_sym]
            books_row << detail[:jpn_donate][price_sym] if conditions.money_aggregation.present?
            books_row << detail[:foreign_donate][book_sym]
            books_row << detail[:foreign_donate][price_sym] if conditions.money_aggregation.present?
            books_row << detail[:donate][book_sym]
            books_row << detail[:donate][price_sym] if conditions.money_aggregation.present?
            sum_donate_book += detail[:donate][book_sym]
            sum_donate_price += detail[:donate][price_sym] if conditions.money_aggregation.present?
          end
          books_row << sum_donate_book
          books_row << sum_donate_price if conditions.money_aggregation.present?
          total_book += sum_donate_book
          total_price += sum_donate_price if conditions.money_aggregation.present?
        else
          books_row << second_row[:detail][:jpn_not_donate][book_sym]
          books_row << second_row[:detail][:jpn_not_donate][price_sym] if conditions.money_aggregation.present?
          books_row << second_row[:detail][:foreign_not_donate][book_sym]
          books_row << second_row[:detail][:foreign_not_donate][price_sym] if conditions.money_aggregation.present?
          books_row << second_row[:detail][:not_donate][book_sym]
          books_row << second_row[:detail][:not_donate][price_sym] if conditions.money_aggregation.present?
          books_row << second_row[:detail][:jpn_donate][book_sym]
          books_row << second_row[:detail][:jpn_donate][price_sym] if conditions.money_aggregation.present?
          books_row << second_row[:detail][:foreign_donate][book_sym]
          books_row << second_row[:detail][:foreign_donate][price_sym] if conditions.money_aggregation.present?
          books_row << second_row[:detail][:donate][book_sym]
          books_row << second_row[:detail][:donate][price_sym] if conditions.money_aggregation.present?
          total_book += second_row[:detail][:not_donate][book_sym] + second_row[:detail][:donate][book_sym]
          total_price += second_row[:detail][:not_donate][price_sym] + second_row[:detail][:donate][price_sym] if conditions.money_aggregation.present?
        end
        # 総合計
        books_row << total_book
        books_row << total_price if conditions.money_aggregation.present?
        sheet.add_row books_row, :types => :string, :style => default_style
      end
      # 全合計の算出
      if conditions.aggregation_type.present?
        if cols.present?
          datum[:second_row_details].last[:detail].each_with_index do |detail, index|
            detail.each do |key, value|
              value.each do |k, v|
                grand_totals[index][key][k] += v
              end
            end
          end
        else
          datum[:second_row_details].last[:detail].each do |key, value|
            value.each do |k, v|
              grand_total[key][k] += v
            end
          end
        end
      end
    end
    # 全合計
    if conditions.aggregation_type.present?
      books_row = []
      books_row << I18n.t("statistical_table.grand_total")
      books_row << "-"
      if cols.present?
        sum_not_donate_book = 0
        sum_not_donate_price = 0
        sum_donate_book = 0
        sum_donate_price = 0
        # 寄贈以外
        grand_totals.each do |grand_total|
          books_row << grand_total[:jpn_not_donate][book_sym]
          books_row << grand_total[:jpn_not_donate][price_sym] if conditions.money_aggregation.present?
          books_row << grand_total[:foreign_not_donate][book_sym]
          books_row << grand_total[:foreign_not_donate][price_sym] if conditions.money_aggregation.present?
          books_row << grand_total[:not_donate][book_sym]
          books_row << grand_total[:not_donate][price_sym] if conditions.money_aggregation.present?
          sum_not_donate_book += grand_total[:not_donate][book_sym]
          sum_not_donate_price += grand_total[:not_donate][price_sym] if conditions.money_aggregation.present?
        end
        books_row << sum_not_donate_book
        books_row << sum_not_donate_price if conditions.money_aggregation.present?
        # 寄贈
        grand_totals.each do |grand_total|
          books_row << grand_total[:jpn_donate][book_sym]
          books_row << grand_total[:jpn_donate][price_sym] if conditions.money_aggregation.present?
          books_row << grand_total[:foreign_donate][book_sym]
          books_row << grand_total[:foreign_donate][price_sym] if conditions.money_aggregation.present?
          books_row << grand_total[:donate][book_sym]
          books_row << grand_total[:donate][price_sym] if conditions.money_aggregation.present?
          sum_donate_book += grand_total[:donate][book_sym]
          sum_donate_price += grand_total[:donate][price_sym] if conditions.money_aggregation.present?
        end
        books_row << sum_donate_book
        books_row << sum_donate_price if conditions.money_aggregation.present?
        books_row << sum_not_donate_book + sum_donate_book
        books_row << sum_not_donate_price + sum_donate_price if conditions.money_aggregation.present?
      else
        books_row << grand_total[:jpn_not_donate][book_sym]
        books_row << grand_total[:jpn_not_donate][price_sym] if conditions.money_aggregation.present?
        books_row << grand_total[:foreign_not_donate][book_sym]
        books_row << grand_total[:foreign_not_donate][price_sym] if conditions.money_aggregation.present?
        books_row << grand_total[:not_donate][book_sym]
        books_row << grand_total[:not_donate][price_sym] if conditions.money_aggregation.present?
        books_row << grand_total[:jpn_donate][book_sym]
        books_row << grand_total[:jpn_donate][price_sym] if conditions.money_aggregation.present?
        books_row << grand_total[:foreign_donate][book_sym]
        books_row << grand_total[:foreign_donate][price_sym] if conditions.money_aggregation.present?
        books_row << grand_total[:donate][book_sym]
        books_row << grand_total[:donate][price_sym] if conditions.money_aggregation.present?
        books_row << grand_total[:not_donate][book_sym] + grand_total[:donate][book_sym]
        books_row << grand_total[:not_donate][price_sym] + grand_total[:donate][price_sym] if conditions.money_aggregation.present?
      end
      sheet.add_row books_row, :types => :string, :style => default_style
    end
  end

end

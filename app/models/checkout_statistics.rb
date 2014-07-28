# encoding: utf-8
class CheckoutStatistics
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
  
  attr_accessor :statistical_table_type, :checked_at_from, :checked_at_to, :aggregation_type, :classification_type_id, :first_aggregation, :second_aggregation
                

  validates_presence_of :checked_at_from
  validates_presence_of :checked_at_to
  validates_presence_of :aggregation_type
  validate :checked_at_from_valid?
  validate :checked_at_to_valid?
  validate :checked_at_range_valid?
  
  def self.first_aggregations
    return [[I18n.t('statistical_table.first_aggregation.user_group'), 'user_group']]
  end
  
  def self.second_aggregations
    return [[I18n.t('statistical_table.second_aggregation.grade'), 'grade']]
  end

  def make_data
    # 集計日付を求める
    if md = self.checked_at_from.match(/^([0-9]{4})-([0-9]{2})$/)
      checked_at_from = "#{md[1]}-#{md[2]}-01"
    else
      checked_at_from = self.checked_at_from
    end
    if md = self.checked_at_to.match(/^([0-9]{4})-([0-9]{2})$/)
      day = Date.new(md[1].to_i, md[2].to_i, 1).end_of_month
      checked_at_to = day.to_s
    else
      checked_at_to = self.checked_at_to
    end
    
    # 集計方法1
    if self.aggregation_type == "month"
      # 月別
      months = []
      from_date_obj = Date.parse(checked_at_from)
      to_date_obj = Date.parse(checked_at_to)
      # 集計月を求める
      if from_date_obj.mon == to_date_obj.mon
        months << {:display_name => from_date_obj.strftime("%Y-%m"), :from_date => from_date_obj.beginning_of_day, :to_date => to_date_obj.end_of_day}
      else
        if from_date_obj.day != 1
          months << {:display_name => from_date_obj.strftime("%Y-%m"), :from_date => from_date_obj.beginning_of_day, :to_date => from_date_obj.end_of_month.end_of_day}
        end
        (from_date_obj..to_date_obj).each{|i|
            next if i.day != 1
            if from_date_obj.year == i.year && from_date_obj.month == i.month
              from_date = from_date_obj.beginning_of_day
            else
              from_date = i.beginning_of_day
            end
            if to_date_obj.year == i.year && to_date_obj.month == i.month
              to_date = to_date_obj.end_of_day
            else
              to_date = Date.new(i.year, i.month, -1).end_of_day
            end
            months << {:display_name => i.strftime("%Y-%m"), :from_date => from_date, :to_date => to_date}
        }
      end
      cols = months
    elsif self.aggregation_type == "classification_type"
      # 分類別
      classifications = Classification.where("classification_type_id = ?", self.classification_type_id)
      classifications = Classification.where("classification_identifier like '1%'").limit(10)
      cols = classifications
    end
    
    # 集計方法2
    if self.first_aggregation == "user_group"
      first_aggregation_column = "users.user_group_id"
      first_aggregations = UserGroup.all
    end
    if self.second_aggregation == "grade"
      second_aggregation_column = "agents.grade_id"
      second_aggregations =  Keycode.where(:name => 'agent.grade')
    end
    
    data = []
    sum_books = Array.new(cols.length, 0)
    sum_persons = Array.new(cols.length, 0)

    first_aggregations.each do |first_aggregation|
      details = []
      second_aggregations.each do |second_aggregation|
        if User.joins(:agent).where("#{first_aggregation_column} = ?", first_aggregation.id).where("#{second_aggregation_column} = ?", second_aggregation.id).present?
          checkouts = Checkout.joins(:user => :agent)
          checkouts = checkouts.where("#{first_aggregation_column} = ?", first_aggregation.id)
          checkouts = checkouts.where("#{second_aggregation_column} = ?", second_aggregation.id)
          if self.aggregation_type == "classification_type"
            checkouts = checkouts.joins(:item => {:manifestation => :manifestation_has_classifications})
            from_date_obj = Date.parse(checked_at_from)
            to_date_obj = Date.parse(checked_at_to)
            checkouts = checkouts.where("checked_at >= ? and checked_at <= ?", from_date_obj.beginning_of_day, to_date_obj.end_of_day)
          end
          # 冊数
          books = []
          sum_book = 0
          if self.aggregation_type == "month"
            months.each do |month|
              book = checkouts.select("checkouts.id").where("checked_at >= ? and checked_at <= ?", month[:from_date], month[:to_date]).reorder("checkouts.id").uniq
              books << book.length
            end
          elsif self.aggregation_type == "classification_type"
            classifications.each do |classification|
              book = checkouts.where("manifestation_has_classifications.classification_id = ?", classification.id).count()
              books << book
            end
          end
          # 人数
          persons = []
          sum_person = 0
          if self.aggregation_type == "month"
            months.each do |month|
              person = checkouts.select("checkouts.user_id").where("checked_at >= ? and checked_at <= ?", month[:from_date], month[:to_date]).reorder(:user_id).uniq
              persons << person.length
            end
          elsif self.aggregation_type == "classification_type"
            classifications.each do |classification|
              person = checkouts.select("checkouts.user_id").where("manifestation_has_classifications.classification_id = ?", classification.id).reorder(:user_id).uniq
              persons << person.length
            end
          end
          details << {:second_aggregation_name => second_aggregation.keyname, :books => books, :persons => persons}
        end
      end
      # 小計
      books = Array.new(cols.length, 0)
      persons = Array.new(cols.length, 0)
      details.each do |detail|
        cols.each_with_index do |col, index|
          books[index] += detail[:books][index]
          persons[index] += detail[:persons][index]
          sum_books[index] += detail[:books][index]
          sum_persons[index] += detail[:persons][index]
        end
      end
      details << {:second_aggregation_name => I18n.t('statistical_table.subtotal'), :books => books, :persons => persons}
      data << {:first_aggregation_name => first_aggregation.display_name, :details => details}
    end
    # 総合計
    data << {:first_aggregation_name => I18n.t('statistical_table.total'), :details => [{:second_aggregation_name => "", :books => sum_books, :persons => sum_persons}]}

    conditions = self
    conditions.checked_at_from = checked_at_from
    conditions.checked_at_to = checked_at_to
    
    return {:data => data, :cols => cols, :conditions => conditions}
  end

  def self.output_excelx(output_data, filename = nil)
    require 'axlsx'

    # initialize
    if filename.present?
      # 定期作成
      out_dir = "#{Rails.root}/private/system/checkout_statistics"
      excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{filename}.xlsx"
    else
      # 手動作成
      out_dir = "#{Rails.root}/private/user_file/checkout_statistics"
      excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{rand(10)}.xlsx"
    end
    FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)

    Rails.logger.info "output_checkout_statistics_excelx filepath=#{excel_filepath}"

    Axlsx::Package.new do |p|
      wb = p.workbook
      wb.styles do |s|
        sheet = wb.add_worksheet(:name => I18n.t('activemodel.models.checkout_statistics'))
        top_style = s.add_style :font_name => Setting.checkout_statistics_print_excelx.fontname, :sz => 16, :alignment => {:horizontal => :center, :vertical => :center}
        default_style = s.add_style :font_name => Setting.checkout_statistics_print_excelx.fontname
        # ヘッダ
        sheet.add_row [I18n.t('activemodel.models.checkout_statistics')], :types => :string, :style => top_style
        sheet.merge_cells "A1:O1"
        condition = []
        condition << I18n.t('statistical_table.checkout_period') + ":"
        condition << output_data[:conditions].checked_at_from
        condition << "～"
        condition << output_data[:conditions].checked_at_to
        condition << ""
        condition << I18n.t('activemodel.attributes.checkout_statistics.aggregation_type') + ":"
        condition << I18n.t("statistical_table.aggregation_type.#{output_data[:conditions].aggregation_type}")
        if output_data[:conditions].aggregation_type == "classification_type"
          classification_type = ClassificationType.where("id = ?", output_data[:conditions].classification_type_id).first
          condition << classification_type.display_name
        else
          condition << ""
        end
        condition << ""
        condition << I18n.t('activemodel.attributes.checkout_statistics.first_aggregation') + ":"
        condition << I18n.t("statistical_table.first_aggregation.#{output_data[:conditions].first_aggregation}")
        condition << I18n.t("statistical_table.second_aggregation.#{output_data[:conditions].second_aggregation}")
        condition << ""
        condition << I18n.t('statistical_table.output_date') + ":"
        condition << Date.today
        sheet.add_row condition, :types => :string, :style => default_style
        
        # 項目名
        columns = [I18n.t('activerecord.attributes.user.user_group'), I18n.t('activerecord.attributes.agent.grade'), ""]
        if output_data[:conditions].aggregation_type == "month"
          output_data[:cols].each do |month|
            columns << month[:display_name]
          end
        elsif output_data[:conditions].aggregation_type == "classification_type"
          output_data[:cols].each do |classification|
            columns << classification.category
          end
        end
        columns << I18n.t('statistical_table.total')
        sheet.add_row columns, :types => :string, :style => default_style
        
        # データ
        output_data[:data].each do |datum|
          datum[:details].each_with_index do |detail, index|
            # 冊数
            if index == 0
              books_row = [datum[:first_aggregation_name]]
            else
              books_row = [""]
            end
            books_row << detail[:second_aggregation_name]
            books_row << I18n.t('statistical_table.books')
            books_row += detail[:books]
            books_row << detail[:books].inject(:+)
            sheet.add_row books_row, :types => :string, :style => default_style
            # 人数
            persons_row = ["", ""]
            persons_row << I18n.t('statistical_table.persons')
            persons_row += detail[:persons]
            persons_row << detail[:persons].inject(:+)
            sheet.add_row persons_row, :types => :string, :style => default_style
          end
        end
        p.serialize(excel_filepath)
      end
    end
    return excel_filepath
  end

private

  def checked_at_from_valid?
    if checked_at_from.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ checked_at_from || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_from
        errors.add(:checked_at_from)
      end
    end
  end

  def checked_at_to_valid?
    if checked_at_to.present?
      unless /^[0-9]{4}-[0-9]{2}$/ =~ checked_at_to || /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_to
        errors.add(:checked_at_to)
      end
    end
  end

  def checked_at_range_valid?
    if checked_at_from.present? && checked_at_to.present?
      if (/^[0-9]{4}-[0-9]{2}$/ =~ checked_at_from && /^[0-9]{4}-[0-9]{2}$/ =~ checked_at_to) || (/^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_from && /^[0-9]{4}-[0-9]{2}-[0-9]{2}$/ =~ checked_at_to)
      
        if checked_at_from > checked_at_to
          errors.add(:checked_at_from)
        end
      else
        errors.add(:checked_at_from)
      end
    end
  end

end

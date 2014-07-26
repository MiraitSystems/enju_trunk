class StatisticalTableController < ApplicationController

  def index
    @statistical_table_types = [{:id => 'checkout_statistics', :display_name => '貸出統計表'},
                                {:id => 'item_statistics', :display_name => '蔵書統計表'}]
    @statistical_table_type = ''
  end
  
  def get_condition
    if params[:statistical_table_type] == 'checkout_statistics'
      @checkout_statistics = CheckoutStatistics.new(:statistical_table_type => params[:statistical_table_type])
      @classification_types = ClassificationType.all
      @first_aggregations = CheckoutStatistics.first_aggregations
      @second_aggregations = CheckoutStatistics.second_aggregations
      @default_date = Time.now.strftime("%Y-%m-%d")
      html = render_to_string :partial => 'checkout_statistics'
    end
    render :text => html
  end
  
  def output
    @checkout_statistics = CheckoutStatistics.new(params[:checkout_statistics])
    if @checkout_statistics.invalid?
      @statistical_table_type = 'checkout_statistics'
      @statistical_table_types = [{:id => 'checkout_statistics', :display_name => '貸出統計表'},
                                  {:id => 'item_statistics', :display_name => '蔵書統計表'}]
      @classification_types = ClassificationType.all
      @first_aggregations = CheckoutStatistics.first_aggregations
      @second_aggregations = CheckoutStatistics.second_aggregations
      @default_date = Time.now.strftime("%Y-%m-%d")
      render :action => 'index'
    else
      # 集計日付を求める
      if md = @checkout_statistics.checked_at_from.match(/^([0-9]{4})-([0-9]{2})$/)
        checked_at_from = "#{md[1]}-#{md[2]}-01"
      else
        checked_at_from = @checkout_statistics.checked_at_from
      end
      if md = @checkout_statistics.checked_at_to.match(/^([0-9]{4})-([0-9]{2})$/)
        day = Date.new(md[1].to_i, md[2].to_i + 1, 1) - 1
        checked_at_to = day.to_s
      else
        checked_at_to = @checkout_statistics.checked_at_to
      end
      # 月別 集計月を求める
      months = []
      from_date_obj = Date.parse(checked_at_from)
      to_date_obj = Date.parse(checked_at_to)
      if from_date_obj.mon == to_date_obj.mon
        months << {:display_name => from_date_obj.strftime("%Y-%m"), :from_date => checked_at_from, :to_date => checked_at_to}
      else
        if from_date_obj.day != 1
          months << {:display_name => from_date_obj.strftime("%Y-%m"), :from_date => checked_at_from, :to_date => Date.new(from_date_obj.year, from_date_obj.month, -1).to_s}
        end
        (from_date_obj..to_date_obj).each{|i|
            next if i.day != 1
            if from_date_obj.year == i.year && from_date_obj.month == i.month
              from_date = checked_at_from
            else
              from_date = i.strftime("%Y-%m-%d")
            end
            if to_date_obj.year == i.year && to_date_obj.month == i.month
              to_date = checked_at_to
            else
              to_date = Date.new(i.year, i.month, -1).to_s
            end
            months << {:display_name => i.strftime("%Y-%m"), :from_date => from_date, :to_date => to_date}
        }
      end

      # 集計方法2
      if @checkout_statistics.first_aggregation == "user_group"
        first_aggregation_column = "users.user_group_id"
        first_aggregations = UserGroup.all
      end
      if @checkout_statistics.second_aggregation == "grade"
        second_aggregation_column = "agents.grade_id"
        second_aggregations =  Keycode.where(:name => 'agent.grade')
      end
      
      data = []
      sum_books = Array.new(months.length, 0)
      sum_persons = Array.new(months.length, 0)
      first_aggregations.each do |first_aggregation|
        details = []
        second_aggregations.each do |second_aggregation|
          if User.joins(:agent).where("#{first_aggregation_column} = ?", first_aggregation.id).where("#{second_aggregation_column} = ?", second_aggregation.id).present?
            checkouts = Checkout.joins(:user => :agent).where("#{first_aggregation_column} = ?", first_aggregation.id)
            checkouts = checkouts.where("#{second_aggregation_column} = ?", second_aggregation.id)
            # 冊数
            books = []
            sum_book = 0
            months.each do |month|
              book = checkouts.where("checked_at >= ? and checked_at <= ?", month[:from_date], month[:to_date]).count()
              books << book
            end
            # 人数
            persons = []
            sum_person = 0
            months.each do |month|
              person = checkouts.select("checkouts.user_id").where("checked_at >= ? and checked_at <= ?", month[:from_date], month[:to_date]).reorder(:user_id).uniq
              persons << person.length
            end
            details << {:second_aggregation_name => second_aggregation.keyname, :books => books, :persons => persons}
          end
        end
        # 小計
        books = Array.new(months.length, 0)
        persons = Array.new(months.length, 0)
        details.each do |detail|
          months.each_with_index do |month, index|
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

      conditions = {:checked_at_from => checked_at_from, :checked_at_to => checked_at_to,
                    :aggregation_type => @checkout_statistics.aggregation_type,
                    :first_aggregation => @checkout_statistics.first_aggregation,
                    :second_aggregation => @checkout_statistics.second_aggregation}
      send_file output_excelx(data, months, conditions), :filename => "aaa.xlsx"
    end
  end

  def output_excelx(data, months, conditions)
    require 'axlsx'

    # initialize
    out_dir = "#{Rails.root}/private/system/checkout_statistics_excelx"
    excel_filepath = "#{out_dir}/list#{Time.now.strftime('%s')}#{rand(10)}.xlsx"
    FileUtils.mkdir_p(out_dir) unless FileTest.exist?(out_dir)

    logger.info "output_checkout_statistics_excelx filepath=#{excel_filepath}"

    Axlsx::Package.new do |p|
      wb = p.workbook
      wb.styles do |s|
        sheet = wb.add_worksheet(:name => I18n.t('activemodel.models.checkout_statistics'))
        top_style = s.add_style :font_name => "ＭＳ ゴシック", :sz => 16, :alignment => {:horizontal => :center, :vertical => :center}
        default_style = s.add_style :font_name => "ＭＳ ゴシック"
        # ヘッダ
        sheet.add_row [I18n.t('activemodel.models.checkout_statistics')], :types => :string, :style => top_style
        sheet.merge_cells "A1:N1"
        condition = []
        condition << I18n.t('statistical_table.checkout_period') + ":"
        condition << conditions[:checked_at_from]
        condition << "～"
        condition << conditions[:checked_at_to]
        condition << ""
        condition << I18n.t('activemodel.models.checkout_statistics.aggregation_type') + ":"
        condition << I18n.t("statistical_table.aggregation_type.#{conditions[:aggregation_type]}")
        condition << ""
        condition << I18n.t('activemodel.models.checkout_statistics.first_aggregation') + ":"
        condition << I18n.t("statistical_table.first_aggregation.#{conditions[:first_aggregation]}")
        condition << I18n.t("statistical_table.second_aggregation.#{conditions[:second_aggregation]}")
        condition << ""
        condition << I18n.t('statistical_table.output_date') + ":"
        condition << Date.today
        sheet.add_row condition, :types => :string, :style => default_style
        
        # 項目名
        columns = [I18n.t('activerecord.attributes.user.user_group'), I18n.t('activerecord.attributes.agent.grade'), ""]
        months.each do |month|
          columns << month[:display_name]
        end
        columns << I18n.t('statistical_table.total')
        sheet.add_row columns, :types => :string, :style => default_style
        
        # データ
        data.each do |datum|
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

end

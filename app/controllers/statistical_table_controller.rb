class StatisticalTableController < ApplicationController

  # GET /statistical_table
  def index
    @statistical_table_types = I18n.t('statistical_table.statistical_table_types').map{|k,v|[v,k]}
    @statistical_table_type = ''
  end
  
  # GET /statistical_table/get_condition
  def get_condition
    # 貸出統計表
    if params[:statistical_table_type] == 'checkout_statistics'
      @checkout_statistics = CheckoutStatistics.new(:statistical_table_type => params[:statistical_table_type])
      checkout_statistics_prepare_options
      html = render_to_string :partial => 'checkout_statistics'
    end
    # 蔵書統計表
    if params[:statistical_table_type] == 'item_statistics'
      @item_statistics = ItemStatistics.new(:statistical_table_type => params[:statistical_table_type])
      item_statistics_prepare_options
      html = render_to_string :partial => 'item_statistics'
    end
    render :text => html
  end

  # GET /statistical_table/get_aggregation_third
  def get_aggregation_third
    @item_statistics = ItemStatistics.new(:aggregation_second => params[:aggregation_second])
    @aggregation_third_classes = ItemStatistics.aggregation_third_classes
    html = render_to_string :partial => 'item_statistics_aggregation_third'
    render :text => html
  end

  # POST /statistical_table/output
  def output
    # 貸出統計表
    if params[:checkout_statistics].present?
      @checkout_statistics = CheckoutStatistics.new(params[:checkout_statistics])
      if @checkout_statistics.invalid?
        @statistical_table_types = I18n.t('statistical_table.statistical_table_types').map{|k,v|[v,k]}
        @statistical_table_type = 'checkout_statistics'
        checkout_statistics_prepare_options
        render :action => 'index'
      else
        send_file CheckoutStatistics.output_excelx(@checkout_statistics.make_data), :filename => Setting.checkout_statistics_print_excelx.filename
      end
    end
    # 蔵書統計表
    if params[:item_statistics].present?
      @item_statistics = ItemStatistics.new(params[:item_statistics])
      if @item_statistics.invalid?
        @statistical_table_types = I18n.t('statistical_table.statistical_table_types').map{|k,v|[v,k]}
        @statistical_table_type = 'item_statistics'
        item_statistics_prepare_options
        render :action => 'index'
      else
        send_file ItemStatistics.output_excelx(@item_statistics.make_data), :filename => Setting.item_statistics_print_excelx.filename
      end
    end
  end

private

  def checkout_statistics_prepare_options
    @classification_types = ClassificationType.all
    @first_aggregations = CheckoutStatistics.first_aggregations
    @second_aggregations = CheckoutStatistics.second_aggregations
    @default_date = Time.now.strftime("%Y-%m-%d")
  end
  
  def item_statistics_prepare_options
    @librarlies = Library.all
    if Rails.application.class.parent_name == "EnjuWilmina"
      @output_conditions = Keycode.where(:name => "item.asset_category")
    end
    @aggregation_first_classes = ItemStatistics.aggregation_first_classes
    @aggregation_second_classes = ItemStatistics.aggregation_second_classes
    @aggregation_third_classes = ItemStatistics.aggregation_third_classes
    @default_date = Time.now.strftime("%Y-%m-%d")
  end

end

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

  # GET /statistical_table/get_second_aggregation
  def get_second_aggregation
    @item_statistics = ItemStatistics.new(:first_aggregation => params[:first_aggregation])
    @second_aggregations = ItemStatistics.second_aggregations
    html = render_to_string :partial => 'item_statistics_second_aggregation'
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
        send_file CheckoutStatistics.output_excelx(@checkout_statistics.make_data), :filename => Setting.checkout_statistics_print_excelx.filename
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
    @output_conditions = ItemStatistics.output_conditions
    @aggregation_types = ItemStatistics.aggregation_types
    @first_aggregations = ItemStatistics.first_aggregations
    @second_aggregations = ItemStatistics.second_aggregations
    @default_date = Time.now.strftime("%Y-%m-%d")
  end

end
